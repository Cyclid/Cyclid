require 'spec_helper'

describe Cyclid::API::Plugins::Debian do
  # Provide a stub transport
  class TestTransport < Cyclid::API::Plugins::Transport
    attr_reader :exit_code, :cmd

    def initialize(_args = {})
      @exit_code = 0
    end

    def exec(cmd, _path = nil)
      @cmd = cmd
      true
    end

    register_plugin 'test'
  end

  before :all do
    @transport = TestTransport.new
    @buildhost = Cyclid::API::Plugins::BuildHost.new(hostname: 'test.example.com')
  end

  it 'should create a new instance' do
    expect{ Cyclid::API::Plugins::Debian.new }.to_not raise_error
  end

  it 'should prepare a host with an empty environment and packages list' do
    provisioner = nil
    expect{ provisioner = Cyclid::API::Plugins::Debian.new }.to_not raise_error
    expect{ provisioner.prepare(@transport, @buildhost) }.to_not raise_error
  end

  it 'should prepare a host with a list of repositories' do
    env = { repos: ['http://test.example.com/example/test'] }

    provisioner = nil
    expect{ provisioner = Cyclid::API::Plugins::Debian.new }.to_not raise_error
    expect{ provisioner.prepare(@transport, @buildhost, env) }.to_not raise_error
    expect(@transport.cmd).to eq('sudo apt-get update')
  end

  it 'should prepare a host with a list of packages' do
    env = { packages: ['package'] }

    provisioner = nil
    expect{ provisioner = Cyclid::API::Plugins::Debian.new }.to_not raise_error
    expect{ provisioner.prepare(@transport, @buildhost, env) }.to_not raise_error
    expect(@transport.cmd).to eq('sudo apt-get install -y package')
  end
end
