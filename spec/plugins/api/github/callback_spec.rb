# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe Cyclid::API::Plugins::ApiExtension::GithubCallback do
  it 'creates a new instance' do
    expect{ Cyclid::API::Plugins::ApiExtension::GithubCallback.new(nil, nil, nil, nil) }.to_not raise_error
  end

  context 'updating the status' do
    let :fakeclient do
      instance_double(Octokit::Client)
    end

    let :status_url do
      'http://example.com/statuses/test'
    end

    it 'sends an update on a "WATING" status' do
      allow(fakeclient).to receive(:create_status).and_return(true)
      allow(Octokit::Client).to receive(:new).and_return(fakeclient)

      callback = Cyclid::API::Plugins::ApiExtension::GithubCallback.new(status_url, nil, nil, nil)
      expect{ callback.status_changed(1, Cyclid::API::Constants::JobStatus::WAITING) }.to_not raise_error
    end

    it 'sends an update on a "STARTED" status' do
      allow(fakeclient).to receive(:create_status).and_return(true)
      allow(Octokit::Client).to receive(:new).and_return(fakeclient)

      callback = Cyclid::API::Plugins::ApiExtension::GithubCallback.new(status_url, nil, nil, nil)
      expect{ callback.status_changed(1, Cyclid::API::Constants::JobStatus::STARTED) }.to_not raise_error
    end

    it 'sends an update on a "FAILING" status' do
      allow(fakeclient).to receive(:create_status).and_return(true)
      allow(Octokit::Client).to receive(:new).and_return(fakeclient)

      callback = Cyclid::API::Plugins::ApiExtension::GithubCallback.new(status_url, nil, nil, nil)
      expect{ callback.status_changed(1, Cyclid::API::Constants::JobStatus::FAILING) }.to_not raise_error
    end

    it 'does not send an update for other statuses' do
      allow(fakeclient).to receive(:create_status).and_return(true)
      allow(Octokit::Client).to receive(:new).and_return(fakeclient)

      callback = Cyclid::API::Plugins::ApiExtension::GithubCallback.new(status_url, nil, nil, nil)
      expect(callback.status_changed(1, Cyclid::API::Constants::JobStatus::FAILED)).to be false
    end
  end

  context 'notifying completion' do
    let :fakeclient do
      instance_double(Octokit::Client)
    end

    let :status_url do
      'http://example.com/statuses/test'
    end

    it 'sends and update when the job completes successfully' do
      allow(fakeclient).to receive(:create_status).and_return(true)
      allow(Octokit::Client).to receive(:new).and_return(fakeclient)

      callback = Cyclid::API::Plugins::ApiExtension::GithubCallback.new(status_url, nil, nil, nil)
      expect{ callback.completion(1, true) }.to_not raise_error
    end

    it 'sends and update when the job completes unsuccessfully' do
      allow(fakeclient).to receive(:create_status).and_return(true)
      allow(Octokit::Client).to receive(:new).and_return(fakeclient)

      callback = Cyclid::API::Plugins::ApiExtension::GithubCallback.new(status_url, nil, nil, nil)
      expect{ callback.completion(1, false) }.to_not raise_error
    end
  end
end
