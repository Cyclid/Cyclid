# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe Cyclid::API::Plugins::ApiExtension::GithubStatus do
  context 'successfully sending a status update' do
    before :each do
      # Successful HTTP
      stub_request(:post, 'http://example.com/statuses/test')
        .with(body: '{"state":"pending","target_url":"http://cyclid.io","description":"this is a test","context":"continuous-integration/cyclid"}',
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})

      # Successful HTTPS
      stub_request(:post, 'https://example.com/statuses/test')
        .with(body: '{"state":"pending","target_url":"http://cyclid.io","description":"this is a test","context":"continuous-integration/cyclid"}',
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: '', headers: {})
    end

    it 'sends an anauthenticated status update to the Github API' do
      status_url = 'http://example.com/statuses/test'
      state = 'pending'
      desc = 'this is a test'
      expect{ Cyclid::API::Plugins::ApiExtension::GithubStatus.set_status(status_url, nil, state, desc) }.to_not raise_error
    end

    it 'sends an authenticated status update to the Github API' do
      status_url = 'http://example.com/statuses/test'
      token = 'abcdefuvwxyz'
      state = 'pending'
      desc = 'this is a test'
      expect{ Cyclid::API::Plugins::ApiExtension::GithubStatus.set_status(status_url, token, state, desc) }.to_not raise_error
    end

    it 'sends a status update using HTTPS' do
      status_url = 'https://example.com/statuses/test'
      state = 'pending'
      desc = 'this is a test'
      expect{ Cyclid::API::Plugins::ApiExtension::GithubStatus.set_status(status_url, nil, state, desc) }.to_not raise_error
    end
  end

  context 'unsuccessfully sending a status update' do
    before :each do
      # Invalid HTTP URL (404)
      stub_request(:post, 'http://example.com/statuses/nonexistant')
        .with(body: '{"state":"pending","target_url":"http://cyclid.io","description":"this is a test","context":"continuous-integration/cyclid"}',
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 404, body: '', headers: {})

      # Failing HTTP URL (500)
      stub_request(:post, 'http://example.com/statuses/fail')
        .with(body: '{"state":"pending","target_url":"http://cyclid.io","description":"this is a test","context":"continuous-integration/cyclid"}',
              headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type' => 'application/json', 'Host' => 'example.com', 'User-Agent' => 'Ruby' })
        .to_return(status: 500, body: '', headers: {})
    end

    it 'handles an invalid status URL' do
      status_url = 'http://example.com/statuses/nonexistant'
      state = 'pending'
      desc = 'this is a test'
      expect{ Cyclid::API::Plugins::ApiExtension::GithubStatus.set_status(status_url, nil, state, desc) }.to raise_error(RuntimeError)
    end

    it 'handles other HTTP failures' do
      status_url = 'http://example.com/statuses/fail'
      state = 'pending'
      desc = 'this is a test'
      expect{ Cyclid::API::Plugins::ApiExtension::GithubStatus.set_status(status_url, nil, state, desc) }.to raise_error(RuntimeError)
    end
  end
end
