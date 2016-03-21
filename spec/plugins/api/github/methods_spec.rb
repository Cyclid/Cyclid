# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe Cyclid::API::Plugins::ApiExtension::GithubMethods do
  # Wrap the module into a test class instance
  module GithubPlugin
    module Test
      class TestMethods
        attr_reader :code, :message

        include Cyclid::API::Plugins::ApiExtension::GithubMethods

        def return_failure(code, message)
          @code = code
          @message = message
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
    expect(@methods.post('{}', headers, nil)).to be true
  end

  it 'responds to a STATUS request' do
    headers = { 'X-Github-Event' => 'status', 'X-Github-Delivery' => '' }
    expect(@methods.post('{}', headers, nil)).to be true
  end

  it 'fails for unsupported requests' do
    headers = { 'X-Github-Event' => 'unsupported', 'X-Github-Delivery' => '' }
    expect{ @methods.post('{}', headers, nil) }.to_not raise_error
    expect(@methods.code).to eq(400)
    expect(@methods.message).to eq("event type 'unsupported' is not supported")
  end

  context 'recieving a Pull Request event' do
    before :all do
      @methods = GithubPlugin::Test::TestMethods.new
    end

    before :each do
      # Status: preparing
      stub_request(:post, 'http://example.com/example/test/status/1234567890')
        .with(body: '{"state":"pending","target_url":"http://cyclid.io","description":"Preparing build","context":"continuous-integration/cyclid"}',
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      # Status: error
      stub_request(:post, 'http://example.com/example/test/status/1234567890')
        .with(body: '{"state":"error","target_url":"http://cyclid.io","description":"No Cyclid job file found","context":"continuous-integration/cyclid"}',
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      stub_request(:post, 'http://example.com/example/test/status/1234567890')
        .with(body: '{"state":"error","target_url":"http://cyclid.io","description":"Couldn\'t retrieve Cyclid job file","context":"continuous-integration/cyclid"}',
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})
    end

    it 'processes a Pull Request with no Cyclid job file' do
      # Return a tree without a Cyclid job file.
      tree = '{"tree":[{"path":"dummy"},{"path":"file"},{"path":"tree"}]}'
      stub_request(:get, 'http://example.com/example/test/tree/1234567890')
        .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: tree, headers: {})

      config = { 'repository_tokens' => [] }
      pr = { 'base' => { 'repo' => { 'html_url' => 'http://example.com/example/test' } },
             'head' => { 'sha' => '1234567890',
                         'ref' => 'abcdefg',
                         'repo' => { 'statuses_url' => 'http://example.com/example/test/status/{sha}',
                                     'trees_url' => 'http://example.com/example/test/tree{/sha}' } } }
      request = { 'action' => 'opened', 'pull_request' => pr }
      headers = { 'X-Github-Event' => 'pull_request', 'X-Github-Delivery' => '' }

      expect(@methods.post(request, headers, config)).to be false
    end

    it 'processes a Pull Request with a Cyclid job file' do
      # Don't actually create a Callback object
      callback = double(Cyclid::API::Plugins::ApiExtension::GithubCallback)
      allow(callback).to receive(:new).and_return(nil)

      # Return a tree with a Cyclid job file.
      tree = '{"tree":[{"path":".cyclid.json", "url": "http://example.com/example/test/cyclid"}]}'
      stub_request(:get, 'http://example.com/example/test/tree/1234567890')
        .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: tree, headers: {})

      # Return the Cyclid job file
      # XXX Issue #20
      job = { sources: [], sequence: [] }
      job_blob = { content: Base64.encode64(job.to_json) }
      stub_request(:get, 'http://example.com/example/test/cyclid')
        .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: job_blob.to_json, headers: {})

      config = { 'repository_tokens' => [] }
      pr = { 'base' => { 'repo' => { 'html_url' => 'http://example.com/example/test' } },
             'head' => { 'sha' => '1234567890',
                         'ref' => 'abcdefg',
                         'repo' => { 'statuses_url' => 'http://example.com/example/test/status/{sha}',
                                     'trees_url' => 'http://example.com/example/test/tree{/sha}' } } }
      request = { 'action' => 'opened', 'pull_request' => pr }
      headers = { 'X-Github-Event' => 'pull_request', 'X-Github-Delivery' => '' }

      expect(@methods.post(request, headers, config)).to be true
    end
  end
end
