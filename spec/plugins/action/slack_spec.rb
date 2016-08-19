# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe Cyclid::API::Plugins::Slack do
  # Stub LogBuffer analogue
  class TestLog
    def write(_data)
      true
    end
  end

  before :all do
    new_database

    @log = TestLog.new
  end

  context 'creating a new instance' do
    it 'creates a new instance with a URL' do
      expect do
        Cyclid::API::Plugins::Slack.new(subject: 'hello world',
                                        url: 'http://example.com')
      end.to_not raise_error
    end

    it 'creates a new instance with a message' do
      expect do
        Cyclid::API::Plugins::Slack.new(subject: 'hello world', message: 'this is a message')
      end.to_not raise_error
    end

    it 'creates a new instance with a color' do
      expect do
        Cyclid::API::Plugins::Slack.new(subject: 'hello world', color: 'warning')
      end.to_not raise_error
    end

    it 'prepares to run the action' do
      slack = nil
      expect do
        slack = Cyclid::API::Plugins::Slack.new(subject: 'hello world',
                                                url: 'http://example.com')
      end .to_not raise_error
      expect{ slack.prepare(transport: nil, ctx: nil) }.to_not raise_error
    end
  end

  context 'sending a notification' do
    it 'sends a notification' do
      stub_request(:post, 'http://example.com/')
        .with(body: { 'payload' => '{"username":"Cyclid","attachments":[{"fallback":"hello world","color":"good","fields":[{"title":"Information","value":"Job ID: \\nJob name: \\nOrganization: admins\\nStarted: \\nEnded: \\n","short":false}]}],"text":"hello world"}' },
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      slack = nil
      expect do
        slack = Cyclid::API::Plugins::Slack.new(subject: 'hello world',
                                                url: 'http://example.com')
      end.to_not raise_error
      expect{ slack.prepare(transport: nil, ctx: { organization: 'admins' }) }.to_not raise_error
      expect(slack.perform(@log)).to match_array([true, '200'])
    end

    it 'sends a notification with a message' do
      stub_request(:post, 'http://example.com/')
        .with(body: { 'payload' => '{"username":"Cyclid","attachments":[{"fallback":"this is a message","color":"warning","fields":[{"title":"Message","value":"this is a message"},{"title":"Information","value":"Job ID: \\nJob name: \\nOrganization: admins\\nStarted: \\nEnded: \\n","short":false}]}],"text":"hello world"}' },
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      slack = nil
      expect do
        slack = Cyclid::API::Plugins::Slack.new(subject: 'hello world',
                                                url: 'http://example.com',
                                                message: 'this is a message',
                                                color: 'warning')
      end.to_not raise_error
      expect{ slack.prepare(transport: nil, ctx: { organization: 'admins' }) }.to_not raise_error
      expect(slack.perform(@log)).to match_array([true, '200'])
    end

    it 'fails if no URL is given' do
      slack = nil
      expect do
        slack = Cyclid::API::Plugins::Slack.new(subject: 'hello world')
      end.to_not raise_error
      expect{ slack.prepare(transport: nil, ctx: { organization: 'admins' }) }.to_not raise_error
      expect(slack.perform(@log)).to match_array([false, 0])
    end
  end

  context 'using contexts' do
    it 'interpolates the context into the subject' do
      stub_request(:post, 'http://example.com/')
        .with(body: { 'payload' => '{"username":"Cyclid","attachments":[{"fallback":"hello data","color":"good","fields":[{"title":"Information","value":"Job ID: \\nJob name: \\nOrganization: admins\\nStarted: \\nEnded: \\n","short":false}]}],"text":"hello data"}' },
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      slack = nil
      expect do
        slack = Cyclid::API::Plugins::Slack.new(subject: 'hello %{test}',
                                                url: 'http://example.com')
      end.to_not raise_error
      expect do
        slack.prepare(transport: nil, ctx: { organization: 'admins', test: 'data' })
      end.to_not raise_error
      expect(slack.perform(@log)).to match_array([true, '200'])
    end

    it 'interpolates the context into the URL' do
      stub_request(:post, 'http://example.com/')
        .with(body: { 'payload' => '{"username":"Cyclid","attachments":[{"fallback":"hello world","color":"good","fields":[{"title":"Information","value":"Job ID: \\nJob name: \\nOrganization: admins\\nStarted: \\nEnded: \\n","short":false}]}],"text":"hello world"}' },
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      slack = nil
      expect do
        slack = Cyclid::API::Plugins::Slack.new(subject: 'hello world',
                                                url: 'http://%{test}')
      end.to_not raise_error
      expect do
        slack.prepare(transport: nil, ctx: { organization: 'admins', test: 'example.com' })
      end.to_not raise_error
      expect(slack.perform(@log)).to match_array([true, '200'])
    end

    it 'interpolates the context into the message' do
      stub_request(:post, 'http://example.com/')
        .with(body: { 'payload' => '{"username":"Cyclid","attachments":[{"fallback":"this is a data","color":"good","fields":[{"title":"Message","value":"this is a data"},{"title":"Information","value":"Job ID: \\nJob name: \\nOrganization: admins\\nStarted: \\nEnded: \\n","short":false}]}],"text":"hello world"}' },
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      slack = nil
      expect do
        slack = Cyclid::API::Plugins::Slack.new(subject: 'hello world',
                                                url: 'http://example.com',
                                                message: 'this is a %{test}')
      end.to_not raise_error
      expect do
        slack.prepare(transport: nil, ctx: { organization: 'admins', test: 'data' })
      end.to_not raise_error
      expect(slack.perform(@log)).to match_array([true, '200'])
    end
  end

  context 'updating the config' do
    before :each do
      @config = Cyclid::API::Plugins::Slack.default_config
    end

    it 'sets the webhook URL' do
      new_config = { 'webhook_url' => 'http://example.com' }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Slack.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'webhook_url'
      expect(updated_config['webhook_url']).to eq('http://example.com')
    end

    it 'un-sets the webhook URL' do
      # Set the webhook URL
      new_config = { 'webhook_url' => 'http://example.com' }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Slack.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'webhook_url'
      expect(updated_config['webhook_url']).to eq('http://example.com')

      # Now un-set it
      new_config = { 'webhook_url' => nil }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Slack.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'webhook_url'
      expect(updated_config['webhook_url']).to be_nil
    end
  end
end
