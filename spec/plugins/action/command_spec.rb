# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Plugins::Command do
  # Provide a stub transport
  class TestTransport < Cyclid::API::Plugins::Transport
    attr_reader :exit_code, :cmd, :path, :env

    def initialize(_args = {})
      @exit_code = 0
    end

    def exec(cmd, args = {})
      @cmd = cmd
      @path = args[:path]
      true
    end

    def export_env(env = {})
      @env = env
    end

    register_plugin 'test'
  end

  before :all do
    @transport = TestTransport.new
    @log = TestLog.new
  end

  context 'creating a new instance' do
    it 'creates a new instance with a command string' do
      expect{ Cyclid::API::Plugins::Command.new(cmd: '/bin/true -a -b') }.to_not raise_error
    end

    it 'creates a new instance with a command array' do
      expect do
        Cyclid::API::Plugins::Command.new(cmd: '/bin/true', args: ['-a', '-b'])
      end.to_not raise_error
    end

    it 'creates a new instance when an environmant is given' do
      env = [{ test: 'data' }]
      expect do
        Cyclid::API::Plugins::Command.new(cmd: '/bin/true', env: env)
      end.to_not raise_error
    end

    it 'creates a new instance when a path is given' do
      expect do
        Cyclid::API::Plugins::Command.new(cmd: '/bin/true', path: '/tmp')
      end.to_not raise_error
    end

    # XXX Issue #18
    it 'fails if no command is given' do
      expect{ Cyclid::API::Plugins::Command.new }.to raise_error
    end

    it 'prepares to run a command' do
      command = nil
      expect{ command = Cyclid::API::Plugins::Command.new(cmd: '/bin/true') }.to_not raise_error
      expect{ command.prepare(transport: nil, ctx: nil) }.to_not raise_error
    end
  end

  context 'performing a command' do
    it 'performs a command given as a string' do
      command = nil
      expect do
        command = Cyclid::API::Plugins::Command.new(cmd: '/bin/true -a -b')
      end.to_not raise_error
      expect{ command.prepare(transport: @transport, ctx: nil) }.to_not raise_error
      expect{ command.perform(@log) }.to_not raise_error
      expect(@transport.cmd).to eq('/bin/true -a -b')
    end

    it 'performs a command given as an array' do
      command = nil
      expect do
        command = Cyclid::API::Plugins::Command.new(cmd: '/bin/true', args: ['-a', '-b'])
      end.to_not raise_error
      expect{ command.prepare(transport: @transport, ctx: nil) }.to_not raise_error
      expect{ command.perform(@log) }.to_not raise_error
      expect(@transport.cmd).to eq('/bin/true -a -b')
    end

    it 'passes the path to the transport' do
      command = nil
      expect do
        command = Cyclid::API::Plugins::Command.new(cmd: '/bin/true', path: '/tmp')
      end.to_not raise_error
      expect{ command.prepare(transport: @transport, ctx: nil) }.to_not raise_error
      expect{ command.perform(@log) }.to_not raise_error
      expect(@transport.cmd).to match(%r{/bin/true})
      expect(@transport.path).to match(%r{/tmp})
    end

    it 'exports the environment' do
      command = nil
      expect do
        command = Cyclid::API::Plugins::Command.new(cmd: '/bin/true',
                                                    path: '/tmp',
                                                    env: { 'test' => 'data' })
      end.to_not raise_error
      expect{ command.prepare(transport: @transport, ctx: nil) }.to_not raise_error
      expect{ command.perform(@log) }.to_not raise_error
      expect(@transport.cmd).to match(%r{/bin/true})
      expect(@transport.path).to match(%r{/tmp})
      expect(@transport.env).to eq('test' => 'data')
    end
  end

  context 'using contexts' do
    it 'interpolates the context into the command' do
      command = nil
      expect do
        command = Cyclid::API::Plugins::Command.new(cmd: '/bin/true %{test}')
      end.to_not raise_error
      expect{ command.prepare(transport: @transport, ctx: { test: 'data' }) }.to_not raise_error
      expect{ command.perform(@log) }.to_not raise_error
      expect(@transport.cmd).to eq('/bin/true data')
    end

    it 'interpolates the context into the path' do
      command = nil
      expect do
        command = Cyclid::API::Plugins::Command.new(cmd: '/bin/true', path: '%{test}')
      end.to_not raise_error
      expect{ command.prepare(transport: @transport, ctx: { test: 'data' }) }.to_not raise_error
      expect{ command.perform(@log) }.to_not raise_error
      expect(@transport.path).to eq('data')
    end

    # XXX Issue #19
    it 'interpolates the context into the environment' do
      command = nil
      expect do
        command = Cyclid::API::Plugins::Command.new(cmd: '/bin/true', env: { data: '%{test}' })
      end.to_not raise_error
      expect{ command.prepare(transport: @transport, ctx: { test: 'data' }) }.to_not raise_error
      expect{ command.perform(@log) }.to_not raise_error
      expect(@transport.env).to eq(data: 'data')
    end
  end
end
