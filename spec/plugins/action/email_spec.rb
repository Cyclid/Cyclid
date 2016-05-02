# rubocop:disable Metrics/LineLength
require 'spec_helper'
require 'mail'

describe Cyclid::API::Plugins::Email do
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
    it 'creates a new instance with a recipiant and message' do
      expect do
        Cyclid::API::Plugins::Email.new(to: 'test@example.com',
                                        message: 'this is a test')
      end.to_not raise_error
    end

    it 'creates a new instance with a subject' do
      expect do
        Cyclid::API::Plugins::Email.new(to: 'test@example.com',
                                        message: 'this is a test',
                                        subject: 'test')
      end.to_not raise_error
    end

    it 'creates a new instance with a color' do
      expect do
        Cyclid::API::Plugins::Email.new(to: 'test@example.com',
                                        message: 'this is a test',
                                        color: 'bisque')
      end.to_not raise_error
    end

    it 'prepares to run the action' do
      email = nil
      expect do
        email = Cyclid::API::Plugins::Email.new(to: 'test@example.com',
                                                message: 'this is a test')
      end .to_not raise_error
      expect{ email.prepare(transport: nil, ctx: nil) }.to_not raise_error
    end
  end

  context 'sending an email' do
    before :each do
      Mail::TestMailer.deliveries.clear

      allow_any_instance_of(Mail::Message).to receive(:deliver) do |mail|
        Mail::TestMailer.new({}).deliver!(mail)
      end
    end

    it 'sends an email' do
      email = nil
      expect do
        email = Cyclid::API::Plugins::Email.new(to: 'test@example.com',
                                                message: 'this is a test')
      end.to_not raise_error
      expect{ email.prepare(transport: nil, ctx: { organization: 'admins' }) }.to_not raise_error
      expect(email.perform(@log)).to match_array([true, 0])

      # Ensure that the email was sent
      expect(Mail::TestMailer.deliveries.count).to eq(1)

      # Check that the contents of the mail are what we expect
      mail = Mail::TestMailer.deliveries.first
      expect(mail.to).to match_array(['test@example.com'])
      expect(mail.parts.first.mime_type).to eq('text/plain')
      expect(mail.parts.last.mime_type).to eq('text/html')
    end

    it 'sends an email with a subject' do
      email = nil
      expect do
        email = Cyclid::API::Plugins::Email.new(to: 'test@example.com',
                                                subject: 'test email',
                                                message: 'this is a test')
      end.to_not raise_error
      expect{ email.prepare(transport: nil, ctx: { organization: 'admins' }) }.to_not raise_error
      expect(email.perform(@log)).to match_array([true, 0])

      # Ensure that the email was sent
      expect(Mail::TestMailer.deliveries.count).to eq(1)

      # Check that the contents of the mail are what we expect
      mail = Mail::TestMailer.deliveries.first
      expect(mail.to).to match_array(['test@example.com'])
      expect(mail.subject).to eq('test email')
      expect(mail.parts.first.mime_type).to eq('text/plain')
      expect(mail.parts.last.mime_type).to eq('text/html')
    end

    it 'sends an email with a color' do
      email = nil
      expect do
        email = Cyclid::API::Plugins::Email.new(to: 'test@example.com',
                                                message: 'this is a test',
                                                color: 'fuchsia')
      end.to_not raise_error
      expect{ email.prepare(transport: nil, ctx: { organization: 'admins' }) }.to_not raise_error
      expect(email.perform(@log)).to match_array([true, 0])

      # Ensure that the email was sent
      expect(Mail::TestMailer.deliveries.count).to eq(1)

      # Check that the contents of the mail are what we expect
      mail = Mail::TestMailer.deliveries.first
      expect(mail.to).to match_array(['test@example.com'])
      expect(mail.parts.first.mime_type).to eq('text/plain')
      expect(mail.parts.last.mime_type).to eq('text/html')
      expect(mail.parts.last.to_s).to match(/background: fuchsia;/)
    end
  end

  context 'using contexts' do
    before :each do
      Mail::TestMailer.deliveries.clear

      allow_any_instance_of(Mail::Message).to receive(:deliver) do |mail|
        Mail::TestMailer.new({}).deliver!(mail)
      end
    end

    it 'interpolates the context into the recipient address' do
      email = nil
      expect do
        email = Cyclid::API::Plugins::Email.new(to: '%{data}@example.com',
                                                message: 'this is a test')
      end.to_not raise_error
      expect{ email.prepare(transport: nil, ctx: { organization: 'admins', data: 'test' }) }.to_not raise_error
      expect(email.perform(@log)).to match_array([true, 0])

      expect(Mail::TestMailer.deliveries.count).to eq(1)

      mail = Mail::TestMailer.deliveries.first
      expect(mail.to).to match_array(['test@example.com'])
    end

    it 'interpolates the context into the subject' do
      email = nil
      expect do
        email = Cyclid::API::Plugins::Email.new(to: 'test@example.com',
                                                subject: 'test %{data}',
                                                message: 'this is a test')
      end.to_not raise_error
      expect{ email.prepare(transport: nil, ctx: { organization: 'admins', data: 'email' }) }.to_not raise_error
      expect(email.perform(@log)).to match_array([true, 0])

      expect(Mail::TestMailer.deliveries.count).to eq(1)

      mail = Mail::TestMailer.deliveries.first
      expect(mail.subject).to eq('test email')
    end

    it 'interpolates the context into the message' do
      email = nil
      expect do
        email = Cyclid::API::Plugins::Email.new(to: 'test@example.com',
                                                message: 'this is %{data}')
      end.to_not raise_error
      expect{ email.prepare(transport: nil, ctx: { organization: 'admins', data: 'a test' }) }.to_not raise_error
      expect(email.perform(@log)).to match_array([true, 0])

      expect(Mail::TestMailer.deliveries.count).to eq(1)

      mail = Mail::TestMailer.deliveries.first
      expect(mail.parts.first.to_s).to match(/this is a test/)
    end
  end

  context 'updating the config' do
    before :each do
      @config = Cyclid::API::Plugins::Email.default_config
    end

    it 'sets the server address' do
      new_config = { 'server' => 'smtp.example.com' }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Email.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'server'
      expect(updated_config['server']).to eq('smtp.example.com')
    end

    it 'sets the server port' do
      new_config = { 'port' => 9999 }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Email.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'port'
      expect(updated_config['port']).to eq(9999)
    end

    it 'sets the from address' do
      new_config = { 'from' => 'sender@example.com' }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Email.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'from'
      expect(updated_config['from']).to eq('sender@example.com')
    end

    it 'sets the username' do
      new_config = { 'username' => 'test@example.com' }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Email.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'username'
      expect(updated_config['username']).to eq('test@example.com')
    end

    it 'sets the password' do
      new_config = { 'password' => 'secret' }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Email.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'password'
      expect(updated_config['password']).to eq('secret')
    end

    it 'un-sets the server address' do
      # Set the server address
      new_config = { 'server' => 'smtp.example.com' }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Email.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'server'
      expect(updated_config['server']).to eq('smtp.example.com')

      # Now un-set it
      new_config = { 'server' => nil }
      updated_config = nil
      expect{ updated_config = Cyclid::API::Plugins::Email.update_config(@config, new_config) }.to_not raise_error
      expect(updated_config).to include 'server'
      expect(updated_config['server']).to be_nil
    end
  end
end
