require 'spec_helper'
require 'json'

describe 'an organization job' do
  include Rack::Test::Methods

  # We don't actually want to dispatch the job to be run anywhere, so provide a minimal test
  # dispatcher
  class TestDispatcher < Cyclid::API::Plugins::Dispatcher
    def dispatch(_job, record, _callback = nil)
      return record.id
    end
  end

  before :all do
    new_database

    Cyclid.dispatcher = TestDispatcher.new
  end

  it 'requires authentication' do
    post '/organizations/admins/jobs'
    expect(last_response.status).to eq(401)
  end

  context 'creating a new job' do
    it 'creates a valid job with an empty sequence' do
      new_job = { name: 'test', environment: {}, sequence: {} }

      authorize 'admin', 'password'
      post_json '/organizations/admins/jobs', new_job.to_json
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to eq('job_id' => 1)
    end

    it 'creates a valid job with stages and a sequence' do
      stages = [{ name: 'test', steps: [{ action: 'command', cmd: '/bin/true' }] }]
      sequence = [{ stage: 'test' }]
      new_job = { name: 'test', environment: {}, stages: stages, sequence: sequence }

      authorize 'admin', 'password'
      post_json '/organizations/admins/jobs', new_job.to_json
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to eq('job_id' => 2)
    end

    it 'fails to create a job with an invalid sequence' do
      sequence = [{ stage: 'test' }]
      new_job = { name: 'test', environment: {}, sequence: sequence }

      authorize 'admin', 'password'
      post_json '/organizations/admins/jobs', new_job.to_json
      expect(last_response.status).to eq(500)
    end

    it 'returns a job record of a submitted job' do
      authorize 'admin', 'password'
      get '/organizations/admins/jobs/1'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to include('id' => 1,
                                  'status' => 0)
    end

    it 'returns the status of a submitted job' do
      authorize 'admin', 'password'
      get '/organizations/admins/jobs/1/status'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to include('job_id' => 1,
                                  'status' => 0)
    end

    it 'returns the log of a submitted job' do
      authorize 'admin', 'password'
      get '/organizations/admins/jobs/1/log'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to include('job_id' => 1,
                                  'log' => nil)
    end

    it 'fails if the new data is invalid' do
      authorize 'admin', 'password'
      post_json '/organizations/admins/jobs', 'this is not valid JSON'
      expect(last_response.status).to eq(400)
    end
  end
end
