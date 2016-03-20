# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe Cyclid::API::Plugins::ApiExtension::GithubCallback do
  it 'creates a new instance' do
    expect{ Cyclid::API::Plugins::ApiExtension::GithubCallback.new(nil, nil) }.to_not raise_error
  end

  context 'updating the status' do
    before :each do
      status_url = 'http://example.com/statuses/test'
      @callback = Cyclid::API::Plugins::ApiExtension::GithubCallback.new(status_url, nil)

      @status = class_double('Cyclid::API::Plugins::ApiExtension::GithubStatus').as_stubbed_const
      allow(@status).to receive(:set_status).with(status_url, nil, 'pending', /Queued job #1/).and_return(true)
      allow(@status).to receive(:set_status).with(status_url, nil, 'pending', /Job #1 started/).and_return(true)
      allow(@status).to receive(:set_status).with(status_url, nil, 'failure', /Job #1 failed/).and_return(true)
    end

    it 'sends an update on a "WATING" status' do
      expect{ @callback.status_changed(1, Cyclid::API::Constants::JobStatus::WAITING) }.to_not raise_error
    end

    it 'sends an update on a "STARTED" status' do
      expect{ @callback.status_changed(1, Cyclid::API::Constants::JobStatus::STARTED) }.to_not raise_error
    end

    it 'sends an update on a "FAILING" status' do
      expect{ @callback.status_changed(1, Cyclid::API::Constants::JobStatus::FAILING) }.to_not raise_error
    end

    it 'does not send an update for other statuses' do
      expect(@callback.status_changed(1, Cyclid::API::Constants::JobStatus::FAILED)).to be false
    end
  end

  context 'notifying completion' do
    before :each do
      status_url = 'http://example.com/statuses/test'
      @callback = Cyclid::API::Plugins::ApiExtension::GithubCallback.new(status_url, nil)

      @status = class_double('Cyclid::API::Plugins::ApiExtension::GithubStatus').as_stubbed_const
      allow(@status).to receive(:set_status).with(status_url, nil, 'success', /Job #1 completed/).and_return(true)
      allow(@status).to receive(:set_status).with(status_url, nil, 'failure', /Job #1 failed/).and_return(true)
    end

    it 'sends and update when the job completes successfully' do
      expect{ @callback.completion(1, true) }.to_not raise_error
    end

    it 'sends and update when the job completes unsuccessfully' do
      expect{ @callback.completion(1, false) }.to_not raise_error
    end
  end
end
