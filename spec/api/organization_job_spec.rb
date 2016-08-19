# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
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

  context 'searching jobs' do
    def new_record(name, status, started, ended = nil)
      org = Cyclid::API::Organization.find(1)

      # New
      job_record = Cyclid::API::JobRecord.new
      job_record.job_name = name
      job_record.status = status
      job_record.started = started.to_s unless started.nil?
      job_record.ended = ended.to_s unless ended.nil?
      job_record.save!

      org.job_records << job_record
    end

    # Create some jobs we can search on
    before :all do
      new_database

      # One of each searchable status
      new_record('test_new', Cyclid::API::Constants::JobStatus::NEW, Time.now)
      new_record('test_waiting', Cyclid::API::Constants::JobStatus::WAITING, Time.now)
      new_record('test_started', Cyclid::API::Constants::JobStatus::STARTED, Time.now)
      new_record('test_success', Cyclid::API::Constants::JobStatus::SUCCEEDED, Time.now, Time.now + 1.hour)
      new_record('test_failed', Cyclid::API::Constants::JobStatus::FAILED, Time.now, Time.now + 1.hour)

      # Some different dates
      time = 1_451_606_400 # 2016-01-01 00:00
      new_record("test_#{time}", Cyclid::API::Constants::JobStatus::SUCCEEDED, Time.at(time), Time.at(time) + 1.hour)
      time = 1_470_009_600 # 2016-08-01 00:00
      new_record("test_#{time}", Cyclid::API::Constants::JobStatus::SUCCEEDED, Time.at(time), Time.at(time) + 1.hour)
      time = 1_470_052_800 # 2016-08-01 12:00
      new_record("test_#{time}", Cyclid::API::Constants::JobStatus::SUCCEEDED, Time.at(time), Time.at(time) + 1.hour)
      time = 1_470_096_000 # 2016-08-02 00:00
      new_record("test_#{time}", Cyclid::API::Constants::JobStatus::SUCCEEDED, Time.at(time), Time.at(time) + 1.hour)
    end

    context 'with no search parameters' do
      let :total do
        Cyclid::API::JobRecord.all.count
      end

      it 'returns a list of jobs' do
        authorize 'admin', 'password'
        get '/organizations/admins/jobs'
        expect(last_response.status).to eq(200)

        res_json = JSON.parse(last_response.body)
        expect(res_json).to match('total' => total, 'offset' => 0, 'limit' => 100, 'records' => a_kind_of(Array))
      end

      it 'returns the job stats' do
        authorize 'admin', 'password'
        get '/organizations/admins/jobs?stats_only=true'
        expect(last_response.status).to eq(200)

        res_json = JSON.parse(last_response.body)
        expect(res_json).to match('total' => total, 'offset' => 0, 'limit' => 100)
      end

      it 'returns the jobs from the offset' do
        authorize 'admin', 'password'
        get '/organizations/admins/jobs?offset=1'
        expect(last_response.status).to eq(200)

        res_json = JSON.parse(last_response.body)
        expect(res_json).to match('total' => total, 'offset' => 1, 'limit' => 100, 'records' => a_kind_of(Array))

        records = res_json['records']
        expect(records.length).to eq(total - 1)
      end

      it 'returns the jobs upto the limit' do
        authorize 'admin', 'password'
        get '/organizations/admins/jobs?limit=1'
        expect(last_response.status).to eq(200)

        res_json = JSON.parse(last_response.body)
        expect(res_json).to match('total' => total, 'offset' => 0, 'limit' => 1, 'records' => a_kind_of(Array))

        records = res_json['records']
        expect(records.length).to eq(1)
      end
    end

    context 'with search parameters' do
      it 'searches by job status' do
        authorize 'admin', 'password'
        get '/organizations/admins/jobs?s_status=0'
        expect(last_response.status).to eq(200)

        res_json = JSON.parse(last_response.body)
        expect(res_json).to match('total' => 1, 'offset' => 0, 'limit' => 100, 'records' => a_kind_of(Array))

        records = res_json['records'].first
        expect(records).to match('id' => 1, 'job_name' => 'test_new', 'job_version' => nil, 'started' => /\A.*\z/, 'ended' => nil, 'status' => 0)
      end

      it 'searches by job name' do
        authorize 'admin', 'password'
        get '/organizations/admins/jobs?s_name=test_failed'
        expect(last_response.status).to eq(200)

        res_json = JSON.parse(last_response.body)
        expect(res_json).to match('total' => 1, 'offset' => 0, 'limit' => 100, 'records' => a_kind_of(Array))

        records = res_json['records'].first
        expect(records).to match('id' => 5, 'job_name' => 'test_failed', 'job_version' => nil, 'started' => /\A.*\z/, 'ended' => /\A.*\z/, 'status' => 11)
      end

      it 'searches between two times' do
        from = Time.at(1_470_009_600).to_s # 2016-08-01 00:00
        to = Time.at(1_470_096_000).to_s   # 2016-08-02 00:00

        authorize 'admin', 'password'
        get URI.encode "/organizations/admins/jobs?s_from=#{from}&s_to=#{to}"
        expect(last_response.status).to eq(200)

        res_json = JSON.parse(last_response.body)
        expect(res_json).to match('total' => 3, 'offset' => 0, 'limit' => 100, 'records' => a_kind_of(Array))

        records = res_json['records']
        expect(records).to match([{ 'id' => 7,
                                    'job_name' => 'test_1470009600',
                                    'job_version' => nil,
                                    'started' => '2016-08-01T00:00:00.000Z',
                                    'ended' => '2016-08-01T01:00:00.000Z',
                                    'status' => 10 },
                                  { 'id' => 8,
                                    'job_name' => 'test_1470052800',
                                    'job_version' => nil,
                                    'started' => '2016-08-01T12:00:00.000Z',
                                    'ended' => '2016-08-01T13:00:00.000Z',
                                    'status' => 10 },
                                  { 'id' => 9,
                                    'job_name' => 'test_1470096000',
                                    'job_version' => nil,
                                    'started' => '2016-08-02T00:00:00.000Z',
                                    'ended' => '2016-08-02T01:00:00.000Z',
                                    'status' => 10 }])
      end

      it 'returns an empty set when no records match' do
        authorize 'admin', 'password'
        get '/organizations/admins/jobs?s_name=test_nonexistent'
        expect(last_response.status).to eq(200)

        res_json = JSON.parse(last_response.body)
        expect(res_json).to match('total' => 0, 'offset' => 0, 'limit' => 100, 'records' => [])
      end
    end
  end
end
