# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe Cyclid::API::Plugins::ApiExtension::GithubMethods do
  # Wrap the module into a test class instance
  module GithubPlugin
    module Test
      class TestStop < StandardError
      end

      class TestMethods
        attr_reader :code, :message

        include Cyclid::API::Plugins::ApiExtension::GithubMethods

        def return_failure(code, message)
          @code = code
          @message = message
          raise TestStop
        end

        # Don't actually create & dispatch a job
        def job_from_definition(_job_definition, _callback)
          true
        end
      end
    end
  end

  before :all do
    @methods = GithubPlugin::Test::TestMethods.new
  end

  it "returns the plugin for it's controller" do
    plugin = nil
    expect{ plugin = @methods.controller_plugin }.to_not raise_error
    expect(plugin).to eq(Cyclid::API::Plugins::Github)
  end

  it 'has a GET callback' do
    expect(@methods).to respond_to(:get)
  end

  it 'has a POST callback' do
    expect(@methods).to respond_to(:post)
  end

  it 'has a PUT callback' do
    expect(@methods).to respond_to(:put)
  end

  it 'has a DELETE callback' do
    expect(@methods).to respond_to(:delete)
  end

  it 'responds to a PING request' do
    headers = { 'X-Github-Event' => 'ping', 'X-Github-Delivery' => '' }
    expect(@methods.post(headers, nil)).to be true
  end

  it 'responds to a STATUS request' do
    headers = { 'X-Github-Event' => 'status', 'X-Github-Delivery' => '' }
    expect(@methods.post(headers, nil)).to be true
  end

  it 'fails for unsupported requests' do
    headers = { 'X-Github-Event' => 'unsupported', 'X-Github-Delivery' => '' }
    expect{ @methods.post(headers, nil) }.to raise_error(GithubPlugin::Test::TestStop)
    expect(@methods.code).to eq(400)
    expect(@methods.message).to eq("event type 'unsupported' is not supported")
  end

  context 'recieving a Pull Request event' do
    before :all do
      @methods = GithubPlugin::Test::TestMethods.new
    end

    before :each do
      # Status: preparing
      stub_request(:post, 'https://api.github.com/repos/example/test/statuses/1234567890')
        .with(body: '{"context":"Cyclid","description":"Preparing build","state":"pending"}',
              headers: { 'Accept' => 'application/vnd.github.v3+json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'token 123456789', 'Content-Type' => 'application/json', 'User-Agent' => /Octokit Ruby Gem/ })
        .to_return(status: 200, body: '', headers: {})

      # Status: error
      stub_request(:post, 'https://api.github.com/repos/example/test/statuses/1234567890')
        .with(body: '{"context":"Cyclid","description":"No Cyclid job file found","state":"error"}',
              headers: { 'Accept' => 'application/vnd.github.v3+json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'token 123456789', 'Content-Type' => 'application/json', 'User-Agent' => /Octokit Ruby Gem/ })
        .to_return(status: 200, body: '', headers: {})
    end

    it 'processes a Pull Request with no Cyclid job file' do
      # Return a tree without a Cyclid job file.
      tree = '{"tree":[{"path":"dummy"},{"path":"file"},{"path":"tree"}]}'
      stub_request(:get, 'https://api.github.com/repos/example/test/git/trees/1234567890?recursive=false')
        .with(headers: { 'Accept' => 'application/vnd.github.v3+json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'token 123456789', 'Content-Type' => 'application/json', 'User-Agent' => /Octokit Ruby Gem/ })
        .to_return(status: 200, body: tree, headers: { 'Content-Type' => 'application/vnd.github.v3+json' })

      config = { 'repository_tokens' => [], 'oauth_token' => '123456789' }
      pr = { 'statuses_url' => 'http://example.com/example/test/status/{sha}',
             'base' => { 'repo' => { 'html_url' => 'http://example.com/example/test' } },
             'head' => { 'sha' => '1234567890',
                         'ref' => 'abcdefg',
                         'repo' => { 'html_url' => 'http://example.com/example/test',
                                     'trees_url' => 'http://example.com/example/test/tree{/sha}' } } }
      headers = { 'X-Github-Event' => 'pull_request', 'X-Github-Delivery' => '' }
      expect(@methods).to receive(:parse_request_body).and_return('action' => 'opened', 'pull_request' => pr)

      expect{ @methods.post(headers, config) }.to raise_error(GithubPlugin::Test::TestStop)
    end

    it 'processes a Pull Request with a JSON Cyclid job file' do
      # Don't actually create a Callback object
      callback = double(Cyclid::API::Plugins::ApiExtension::GithubCallback)
      allow(callback).to receive(:new).and_return(nil)

      # Return a tree with a JSON Cyclid job file.
      tree = '{"tree":[{"path":".cyclid.json", "url": "http://example.com/example/test/cyclid"}]}'
      stub_request(:get, 'https://api.github.com/repos/example/test/git/trees/1234567890?recursive=false')
        .with(headers: { 'Accept' => 'application/vnd.github.v3+json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'token 123456789', 'Content-Type' => 'application/json', 'User-Agent' => /Octokit Ruby Gem/ })
        .to_return(status: 200, body: tree, headers: { 'Content-Type' => 'application/vnd.github.v3+json' })

      # Return the Cyclid job file
      job = { sources: [], sequence: [] }
      job_blob = { content: Base64.encode64(job.to_json) }
      stub_request(:get, 'http://example.com/example/test/cyclid')
        .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: job_blob.to_json, headers: {})

      config = { 'repository_tokens' => [], 'oauth_token' => '123456789' }
      pr = { 'statuses_url' => 'http://example.com/example/test/status/{sha}',
             'base' => { 'repo' => { 'html_url' => 'http://example.com/example/test' } },
             'head' => { 'sha' => '1234567890',
                         'ref' => 'abcdefg',
                         'repo' => { 'html_url' => 'http://example.com/example/test',
                                     'trees_url' => 'http://example.com/example/test/tree{/sha}' } } }
      headers = { 'X-Github-Event' => 'pull_request', 'X-Github-Delivery' => '' }
      expect(@methods).to receive(:parse_request_body).and_return('action' => 'opened', 'pull_request' => pr)

      expect{ @methods.post(headers, config) }.to raise_error(GithubPlugin::Test::TestStop)
    end

    # Issue #20
    it 'processes a Pull Request with a YAML Cyclid job file' do
      # Don't actually create a Callback object
      callback = double(Cyclid::API::Plugins::ApiExtension::GithubCallback)
      allow(callback).to receive(:new).and_return(nil)

      # Return a tree with a YAML Cyclid job file.
      tree = '{"tree":[{"path":".cyclid.yml", "url": "http://example.com/example/test/cyclid"}]}'
      stub_request(:get, 'https://api.github.com/repos/example/test/git/trees/1234567890?recursive=false')
        .with(headers: { 'Accept' => 'application/vnd.github.v3+json', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization' => 'token 123456789', 'Content-Type' => 'application/json', 'User-Agent' => /Octokit Ruby Gem/ })
        .to_return(status: 200, body: tree, headers: { 'Content-Type' => 'application/vnd.github.v3+json' })

      # Return the Cyclid job file
      job = { sources: [], sequence: [] }
      job_blob = { content: Base64.encode64(job.to_yaml) }
      stub_request(:get, 'http://example.com/example/test/cyclid')
        .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: job_blob.to_json, headers: {})

      config = { 'repository_tokens' => [], 'oauth_token' => '123456789' }
      pr = { 'statuses_url' => 'http://example.com/example/test/status/{sha}',
             'base' => { 'repo' => { 'html_url' => 'http://example.com/example/test' } },
             'head' => { 'sha' => '1234567890',
                         'ref' => 'abcdefg',
                         'repo' => { 'html_url' => 'http://example.com/example/test',
                                     'trees_url' => 'http://example.com/example/test/tree{/sha}' } } }
      headers = { 'X-Github-Event' => 'pull_request', 'X-Github-Delivery' => '' }
      expect(@methods).to receive(:parse_request_body).and_return('action' => 'opened', 'pull_request' => pr)

      expect{ @methods.post(headers, config) }.to raise_error(GithubPlugin::Test::TestStop)
    end
  end
end
