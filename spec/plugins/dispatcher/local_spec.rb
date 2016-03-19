require 'spec_helper'
require 'sidekiq/testing'

class TestCallback < Cyclid::API::Plugins::Notifier::Callback
  attr_reader :complete, :status, :log

  def initialize
    @complete = false
    @status = false
    @log = false
  end

  def completion(_job_id, _status)
    @complete = true
  end

  def status_changed(_job_id, _status)
    @status = true
  end

  def log_write(_job_id, _data)
    @log = true
  end
end

describe Cyclid::API::Plugins::Local do
  before :all do
    Sidekiq::Testing.fake!
  end

  it 'creates a new instance' do
    expect{ Cyclid::API::Plugins::Local.new }.to_not raise_error
  end

  context 'dispatching a new job' do
    before :each do
      @dispatcher = Cyclid::API::Plugins::Local.new

      new_database
      @job_record = Cyclid::API::JobRecord.new
      @org = Cyclid::API::Organization.find(1)
    end

    it 'creates a new worker' do
      job_def = { name: 'test', environment: {}, sources: [], sequence: {} }

      job_view = nil
      expect{ job_view = Cyclid::API::Job::JobView.new(job_def, @org) }.to_not raise_error

      expect do
        @dispatcher.dispatch(job_view, @job_record)
      end.to change(Cyclid::API::Plugins::Worker::Local.jobs, :size).by(1)
    end

    it 'creates a new worker with a callback object' do
      job_def = { name: 'test', environment: {}, sources: [], sequence: {} }

      job_view = nil
      expect{ job_view = Cyclid::API::Job::JobView.new(job_def, @org) }.to_not raise_error

      expect do
        @dispatcher.dispatch(job_view, @job_record, TestCallback.new)
      end.to change(Cyclid::API::Plugins::Worker::Local.jobs, :size).by(1)
    end
  end
end

describe Cyclid::API::Plugins::Notifier::Local do
  before :all do
    new_database
    @job_record = Cyclid::API::JobRecord.new
    @job_record.save!
  end

  context 'without a callback' do
    it 'creates a new instance' do
      expect do
        Cyclid::API::Plugins::Notifier::Local.new(@job_record.id, nil)
      end.to_not raise_error
    end

    it 'updates the status' do
      notifier = nil
      expect do
        notifier = Cyclid::API::Plugins::Notifier::Local.new(@job_record.id, nil)
      end.to_not raise_error

      expect{ notifier.status = 999 }.to_not raise_error

      db_record = Cyclid::API::JobRecord.find(@job_record.id)
      expect(db_record.status).to eq(999)
    end

    it 'updates the end time' do
      notifier = nil
      expect do
        notifier = Cyclid::API::Plugins::Notifier::Local.new(@job_record.id, nil)
      end.to_not raise_error

      time = Time.now
      expect{ notifier.ended = time }.to_not raise_error

      db_record = Cyclid::API::JobRecord.find(@job_record.id)
      expect(db_record.ended).to eq(time)
    end

    it 'writes data to the buffer' do
      notifier = nil
      expect do
        notifier = Cyclid::API::Plugins::Notifier::Local.new(@job_record.id, nil)
      end.to_not raise_error

      expect{ notifier.write('this is a test') }.to_not raise_error

      db_record = Cyclid::API::JobRecord.find(@job_record.id)
      expect(db_record.log).to eq('this is a test')
    end
  end

  context 'with a callback' do
    before :all do
      @callback = TestCallback.new
    end

    it 'creates a new instance with a callback object' do
      expect do
        Cyclid::API::Plugins::Notifier::Local.new(@job_record.id, @callback)
      end.to_not raise_error
    end

    it 'creates a new instance' do
      expect do
        Cyclid::API::Plugins::Notifier::Local.new(@job_record.id, @callback)
      end.to_not raise_error
    end

    it 'updates the status' do
      notifier = nil
      expect do
        notifier = Cyclid::API::Plugins::Notifier::Local.new(@job_record.id, @callback)
      end.to_not raise_error

      expect{ notifier.status = 999 }.to_not raise_error
      expect(@callback.status).to be true
    end

    it 'calls on completion' do
      notifier = nil
      expect do
        notifier = Cyclid::API::Plugins::Notifier::Local.new(@job_record.id, @callback)
      end.to_not raise_error

      expect{ notifier.completion(true) }.to_not raise_error
      expect(@callback.complete).to be true
    end

    it 'writes data to the buffer' do
      notifier = nil
      expect do
        notifier = Cyclid::API::Plugins::Notifier::Local.new(@job_record.id, @callback)
      end.to_not raise_error

      expect{ notifier.write('this is a test') }.to_not raise_error
      expect(@callback.log).to be true
    end
  end
end

describe Cyclid::API::Plugins::Worker::Local do
  class TestBuilder < Cyclid::API::Plugins::Builder
    def get(*_args)
      raise 'test builder'
    end
  end

  before :all do
    # Stub a fail-fast Builder so that we don't try to run the job
    Cyclid.builder = TestBuilder

    new_database
    @job_record = Cyclid::API::JobRecord.new
    @job_record.save!
  end

  it 'creates an instance' do
    expect{ Cyclid::API::Plugins::Worker::Local.new }.to_not raise_error
  end

  # There is a LOT of code sat behind this single method; most of it is covered by the job tests,
  # and we provide a Builder that will fail so that we don't need to stub out most of the code to
  # make the Job runner work.
  it 'performs a job' do
    job_json = { name: 'test', environment: {}, sources: [], sequence: {} }.to_json

    worker = nil
    expect{ worker = Cyclid::API::Plugins::Worker::Local.new }.to_not raise_error
    expect{ worker.perform(job_json, @job_record.id, nil) }.to_not raise_error
  end
end
