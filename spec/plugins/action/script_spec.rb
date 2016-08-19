# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
require 'spec_helper'

describe Cyclid::API::Plugins::Script do
  # Provide a stub transport
  class TestTransport < Cyclid::API::Plugins::Transport
    attr_reader :exit_code, :cmd, :env, :upl

    def initialize(_args = {})
      @exit_code = 0
    end

    def exec(cmd, path = nil)
      @cmd = cmd
      @path = path
      true
    end

    def upload(io, _path)
      @upl = io.read
    end

    def export_env(env = {})
      @env = env
    end

    register_plugin 'test'
  end

  # Stub LogBuffer analogue
  class TestLog
    def write(_data)
      true
    end
  end

  before :all do
    @transport = TestTransport.new
    @log = TestLog.new
  end

  context 'creating a new instance' do
    it 'creates a new instance with a script as a string' do
      expect{ Cyclid::API::Plugins::Script.new(script: '#!/bin/sh\n/bin/true') }.to_not raise_error
    end

    it 'creates a new instance with a script as an array' do
      expect{ Cyclid::API::Plugins::Script.new(script: ['#!/bin/sh', '/bin/true']) }.to_not raise_error
    end

    it 'creates a new instance when an environmant is given' do
      env = [{ test: 'data' }]
      expect do
        Cyclid::API::Plugins::Script.new(script: '#!/bin/sh\n/bin/true', env: env)
      end.to_not raise_error
    end

    it 'creates a new instance when a path is given' do
      expect do
        Cyclid::API::Plugins::Script.new(script: '#!/bin/sh\n/bin/true', path: '/tmp/file')
      end.to_not raise_error
    end

    it 'fails if no script is given' do
      expect{ Cyclid::API::Plugins::Script.new }.to raise_error
    end

    it 'prepares to run a script' do
      script = nil
      expect{ script = Cyclid::API::Plugins::Script.new(script: '#!/bin/sh\n/bin/true') }.to_not raise_error
      expect{ script.prepare(transport: nil, ctx: nil) }.to_not raise_error
    end
  end

  context 'performing a script' do
    it 'performs a script given as a string' do
      script = nil
      expect do
        script = Cyclid::API::Plugins::Script.new(script: '#!/bin/sh\n/bin/true', path: '/tmp/file')
      end.to_not raise_error
      expect{ script.prepare(transport: @transport, ctx: nil) }.to_not raise_error
      expect{ script.perform(@log) }.to_not raise_error
      expect(@transport.cmd).to eq('chmod +x /tmp/file && /tmp/file')
      expect(@transport.upl).to eq('#!/bin/sh\n/bin/true')
    end

    it 'performs a script given as an array' do
      script = nil
      expect do
        script = Cyclid::API::Plugins::Script.new(script: ['#!/bin/sh', '/bin/true'], path: '/tmp/file')
      end.to_not raise_error
      expect{ script.prepare(transport: @transport, ctx: nil) }.to_not raise_error
      expect{ script.perform(@log) }.to_not raise_error
      expect(@transport.cmd).to eq('chmod +x /tmp/file && /tmp/file')
      expect(@transport.upl).to eq("#!/bin/sh\n/bin/true")
    end

    it 'exports the environment' do
      script = nil
      expect do
        script = Cyclid::API::Plugins::Script.new(script: '#!/bin/sh\n/bin/true',
                                                  path: '/tmp/file',
                                                  env: { 'test' => 'data' })
      end.to_not raise_error
      expect{ script.prepare(transport: @transport, ctx: nil) }.to_not raise_error
      expect{ script.perform(@log) }.to_not raise_error
      expect(@transport.cmd).to eq('chmod +x /tmp/file && /tmp/file')
      expect(@transport.upl).to eq('#!/bin/sh\n/bin/true')
      expect(@transport.env).to eq('test' => 'data')
    end
  end

  context 'using contexts' do
    it 'interpolates the context into the script' do
      script = nil
      expect do
        script = Cyclid::API::Plugins::Script.new(script: '#!/bin/sh\n/bin/true %{test}')
      end.to_not raise_error
      expect{ script.prepare(transport: @transport, ctx: { test: 'data' }) }.to_not raise_error
      expect{ script.perform(@log) }.to_not raise_error
      expect(@transport.upl).to eq('#!/bin/sh\n/bin/true data')
    end

    it 'interpolates the context into the path' do
      script = nil
      expect do
        script = Cyclid::API::Plugins::Script.new(script: '#!/bin/sh\n/bin/true', path: '%{test}')
      end.to_not raise_error
      expect{ script.prepare(transport: @transport, ctx: { test: 'data' }) }.to_not raise_error
      expect{ script.perform(@log) }.to_not raise_error
      expect(@transport.cmd).to eq('chmod +x data && data')
    end

    it 'interpolates the context into the environment' do
      script = nil
      expect do
        script = Cyclid::API::Plugins::Script.new(script: '#!/bin/sh\n/bin/true', env: { data: '%{test}' })
      end.to_not raise_error
      expect{ script.prepare(transport: @transport, ctx: { test: 'data' }) }.to_not raise_error
      expect{ script.perform(@log) }.to_not raise_error
      expect(@transport.env).to eq(data: 'data')
    end
  end
end
