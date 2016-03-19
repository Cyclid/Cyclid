require 'spec_helper'

describe Cyclid::API::Job::Runner do
  # Provide stub implementations
  class TestBuildHost < Cyclid::API::Plugins::BuildHost
    def transports
      ['test']
    end
  end

  class JobTestBuilder < Cyclid::API::Plugins::Builder
    def get(*_args)
      TestBuildHost.new(host: 'test.example.com',
                        username: 'test',
                        password: nil,
                        distro: 'test')
    end
  end

  class TestTransport < Cyclid::API::Plugins::Transport
    attr_reader :exit_code

    def initialize(_args = {})
      @exit_code = 0
    end

    def exec(_cmd, _path = nil)
      true
    end

    register_plugin 'test'
  end

  class TestProvisioner < Cyclid::API::Plugins::Provisioner
    def prepare(_transport, _buildhost, _env = {})
      true
    end

    register_plugin 'test'
  end

  class TestSource < Cyclid::API::Plugins::Source
    def checkout(_transport, _ctx, _source = {})
      true
    end

    register_plugin 'test'
  end

  before :all do
    new_database
    @org = Cyclid::API::Organization.find(1)

    Cyclid.builder = JobTestBuilder
    @notifier = Cyclid::API::Plugins::Notifier::Base.new(nil, nil)
  end

  # XXX Issue #15
  it 'creates a job given a valid job definition' do
    job_json = { name: 'test', environment: {}, sources: [], sequence: {} }.to_json

    expect{ Cyclid::API::Job::Runner.new(1, job_json, @notifier) }.to_not raise_error
  end

  # XXX Issue #16
  it 'runs a job with an empty sequence' do
    job_def = { name: 'test', environment: {}, sources: [], sequence: {} }

    job_view = nil
    expect{ job_view = Cyclid::API::Job::JobView.new(job_def, @org) }.to_not raise_error

    job_json = nil
    expect{ job_json = job_view.to_hash.to_json }.to_not raise_error

    job = nil
    expect{ job = Cyclid::API::Job::Runner.new(2, job_json, @notifier) }.to_not raise_error
    expect{ job.run }.to_not raise_error
  end

  it 'runs a job with a defined sequence' do
    # XXX Issue #17
    stages = [{ name: 'test', steps: [{ 'action' => 'command', 'cmd' => '/bin/true' }] }]
    sequence = [{ stage: 'test' }]
    job_def = { name: 'test',
                environment: {},
                sources: [],
                stages: stages,
                sequence: sequence }

    job_view = nil
    expect{ job_view = Cyclid::API::Job::JobView.new(job_def, @org) }.to_not raise_error

    job_json = nil
    expect{ job_json = job_view.to_hash.to_json }.to_not raise_error

    job = nil
    expect{ job = Cyclid::API::Job::Runner.new(3, job_json, @notifier) }.to_not raise_error
    expect{ job.run }.to_not raise_error
  end

  it 'checks out sources' do
    sources = [{ type: 'test', data: 'test' }]
    stages = [{ name: 'test', steps: [{ 'action' => 'command', 'cmd' => '/bin/true' }] }]
    sequence = [{ stage: 'test' }]
    job_def = { name: 'test',
                environment: {},
                sources: sources,
                stages: stages,
                sequence: sequence }

    job_view = nil
    expect{ job_view = Cyclid::API::Job::JobView.new(job_def, @org) }.to_not raise_error

    job_json = nil
    expect{ job_json = job_view.to_hash.to_json }.to_not raise_error

    job = nil
    expect{ job = Cyclid::API::Job::Runner.new(4, job_json, @notifier) }.to_not raise_error
    expect{ job.run }.to_not raise_error
  end

  it 'fails if the job definition is invalid' do
    expect{ Cyclid::API::Job::Runner.new(5, 'this is not valid JSON', @notifier) }.to raise_error
  end
end
