# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
require 'spec_helper'
require 'json'

describe 'a health check' do
  include Rack::Test::Methods

  let :fakestats do
    instance_double(Sidekiq::Stats)
  end

  before do
    allow(Sidekiq::Stats).to receive(:new).and_return(fakestats)
  end

  context 'when the application is healthy' do
    before do
      allow_any_instance_of(SinatraHealthCheck::Checker).to receive(:healthy?).and_return true
    end

    describe 'GET /health/status' do
      it 'returns a 200 response' do
        get '/health/status'
        expect(last_response.status).to eq(200)
      end
    end

    describe 'GET /health/info' do
      it 'returns a JSON response' do
        allow(fakestats).to receive(:processes_size).and_return(1)
        allow(fakestats).to receive(:enqueued).and_return(0)
        allow(fakestats).to receive(:default_queue_latency).and_return(0)

        get '/health/info'
        expect(last_response.status).to eq(200)

        res = JSON.parse(last_response.body)
        expect(res['status']).to eq 'OK'
      end
    end
  end

  context 'when the application is unhealthy' do
    before do
      allow_any_instance_of(SinatraHealthCheck::Checker).to receive(:healthy?).and_return false
    end

    describe 'GET /health/status' do
      it 'returns a 503 response' do
        get '/health/status'
        expect(last_response.status).to eq(503)
      end
    end

    describe 'GET /health/info' do
      it 'returns a JSON response' do
        allow(fakestats).to receive(:processes_size).and_return(0)
        allow(fakestats).to receive(:enqueued).and_return(99)
        allow(fakestats).to receive(:default_queue_latency).and_return(99)

        get '/health/info'
        expect(last_response.status).to eq(200)

        res = JSON.parse(last_response.body)
        expect(res['status']).to eq 'ERROR'
      end
    end
  end
end

describe Cyclid::API::Health::Database do
  let :fakeconn do
    double('con')
  end

  before do
    allow(ActiveRecord::Base).to receive_message_chain(:connection_pool, :with_connection).and_yield fakeconn
  end

  describe '#status' do
    it 'returns an OK response when the database is connected' do
      allow(fakeconn).to receive(:active?).and_return true

      expect(status = Cyclid::API::Health::Database.status).to be_a(SinatraHealthCheck::Status)
      expect(status.level).to eq(:ok)
      expect(status.message).to eq('database connection is okay')
    end

    it 'returns an error response when the database is not connected' do
      allow(fakeconn).to receive(:active?).and_return false

      expect(status = Cyclid::API::Health::Database.status).to be_a(SinatraHealthCheck::Status)
      expect(status.level).to eq(:error)
      expect(status.message).to eq('database is not connected')
    end
  end
end
