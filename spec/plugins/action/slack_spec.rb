# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe Cyclid::API::Plugins::SlackNotification do
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
        Cyclid::API::Plugins::SlackNotification.new(message: 'hello world',
                                                    url: 'http://example.com')
      end.to_not raise_error
    end

    it 'creates a new instance with a note' do
      expect do
        Cyclid::API::Plugins::SlackNotification.new(message: 'hello world', note: 'this is a note')
      end.to_not raise_error
    end

    it 'creates a new instance with a color' do
      expect do
        Cyclid::API::Plugins::SlackNotification.new(message: 'hello world', color: 'warning')
      end.to_not raise_error
    end

    it 'prepares to run the action' do
      slack = nil
      expect do
        slack = Cyclid::API::Plugins::SlackNotification.new(message: 'hello world',
                                                            url: 'http://example.com')
      end .to_not raise_error
      expect{ slack.prepare(transport: nil, ctx: nil) }.to_not raise_error
    end
  end

  context 'sending a notification' do
    it 'sends a notification' do
      stub_request(:post, 'http://example.com/')
        .with(body: { 'payload' => '{"username":"Cyclid","text":"hello world"}' },
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      slack = nil
      expect do
        slack = Cyclid::API::Plugins::SlackNotification.new(message: 'hello world',
                                                            url: 'http://example.com')
      end.to_not raise_error
      expect{ slack.prepare(transport: nil, ctx: { organization: 'admins' }) }.to_not raise_error
      expect(slack.perform(@log)).to match_array([true, '200'])
    end

    it 'sends a notification with a note' do
      stub_request(:post, 'http://example.com/')
        .with(body: { 'payload' => '{"username":"Cyclid","attachments":[{"fallback":"this is a note","text":"this is a note","color":"warning"}],"text":"hello world"}' },
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      slack = nil
      expect do
        slack = Cyclid::API::Plugins::SlackNotification.new(message: 'hello world',
                                                            url: 'http://example.com',
                                                            note: 'this is a note',
                                                            color: 'warning')
      end.to_not raise_error
      expect{ slack.prepare(transport: nil, ctx: { organization: 'admins' }) }.to_not raise_error
      expect(slack.perform(@log)).to match_array([true, '200'])
    end

    it 'fails if no URL is given' do
      slack = nil
      expect do
        slack = Cyclid::API::Plugins::SlackNotification.new(message: 'hello world')
      end.to_not raise_error
      expect{ slack.prepare(transport: nil, ctx: { organization: 'admins' }) }.to_not raise_error
      expect(slack.perform(@log)).to match_array([false, 0])
    end
  end

  context 'using contexts' do
    it 'interpolates the context into the message' do
      stub_request(:post, 'http://example.com/')
        .with(body: { 'payload' => '{"username":"Cyclid","text":"hello data"}' },
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      slack = nil
      expect do
        slack = Cyclid::API::Plugins::SlackNotification.new(message: 'hello %{test}',
                                                            url: 'http://example.com')
      end.to_not raise_error
      expect do
        slack.prepare(transport: nil, ctx: { organization: 'admins', test: 'data' })
      end.to_not raise_error
      expect(slack.perform(@log)).to match_array([true, '200'])
    end

    it 'interpolates the context into the URL' do
      stub_request(:post, 'http://example.com/')
        .with(body: { 'payload' => '{"username":"Cyclid","text":"hello world"}' },
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      slack = nil
      expect do
        slack = Cyclid::API::Plugins::SlackNotification.new(message: 'hello world',
                                                            url: 'http://%{test}')
      end.to_not raise_error
      expect do
        slack.prepare(transport: nil, ctx: { organization: 'admins', test: 'example.com' })
      end.to_not raise_error
      expect(slack.perform(@log)).to match_array([true, '200'])
    end

    it 'interpolates the context into the note' do
      stub_request(:post, 'http://example.com/')
        .with(body: { 'payload' => '{"username":"Cyclid","attachments":[{"fallback":"this is a data","text":"this is a data","color":"good"}],"text":"hello world"}' },
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      slack = nil
      expect do
        slack = Cyclid::API::Plugins::SlackNotification.new(message: 'hello world',
                                                            url: 'http://example.com',
                                                            note: 'this is a %{test}')
      end.to_not raise_error
      expect do
        slack.prepare(transport: nil, ctx: { organization: 'admins', test: 'data' })
      end.to_not raise_error
      expect(slack.perform(@log)).to match_array([true, '200'])
    end
  end

  context 'updating the config' do
    before :each do
      @config = Cyclid::API::Plugins::SlackNotification.default_config
    end

    it 'sets the webhook URL' do
      new_config = { 'webhook_url' => 'http://example.com' }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::SlackNotification.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'webhook_url'
      expect(updated_config['webhook_url']).to eq('http://example.com')
    end

    it 'un-sets the webhook URL' do
      # Set the webhook URL
      new_config = { 'webhook_url' => 'http://example.com' }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::SlackNotification.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'webhook_url'
      expect(updated_config['webhook_url']).to eq('http://example.com')

      # Now un-set it
      new_config = { 'webhook_url' => nil }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::SlackNotification.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'webhook_url'
      expect(updated_config['webhook_url']).to be_nil
    end
  end
end
