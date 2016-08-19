# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Plugins::Mist do
  # Provide some simple stub
  module MistPlugin
    module Test
      class Pool
        def acquire
          'test.example.com'
        end

        def release(_server)
          true
        end
      end

      class Client
        def call(method, *_args)
          case method
          when :create
            return { 'name' => 'test-host',
                     'ip' => '127.0.0.1',
                     'username' => 'test',
                     'status' => true,
                     'server' => 'test.example.com' }
          when :destroy
            return true
          end
        end
      end
    end
  end

  # Mock mist to return the stub implementations
  before :each do
    @pool = class_double('Mist::Pool').as_stubbed_const
    allow(@pool).to receive(:get).and_return(MistPlugin::Test::Pool.new)

    @client = class_double('Mist::Client').as_stubbed_const
    allow(@client).to receive(:new).and_return(MistPlugin::Test::Client.new)
  end

  it 'should create a new instance' do
    expect{ Cyclid::API::Plugins::Mist.new }.to_not raise_error
  end

  context 'obtaining a build host' do
    before :each do
      @mist = Cyclid::API::Plugins::Mist.new
    end

    it 'returns a host when called with default arguments' do
      expect{ @mist.get }.to_not raise_error
    end

    it 'returns a host when pass an OS in the arguments' do
      buildhost = nil
      expect{ buildhost = @mist.get(os: 'example_test') }.to_not raise_error
      expect(buildhost[:distro]).to eq('example')
      expect(buildhost[:release]).to eq('test')
    end

    it 'returns a host with SSH as the only valid transport' do
      buildhost = @mist.get
      expect(buildhost.transports).to match_array(['ssh'])
    end
  end

  it 'releases a build host' do
    mist = Cyclid::API::Plugins::Mist.new
    buildhost = mist.get
    expect{ mist.release(nil, buildhost) }.to_not raise_error
  end
end
