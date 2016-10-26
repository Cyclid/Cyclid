# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::Plugins::Log do
  # Stub LogBuffer analogue
  class LogTestLog
    attr_reader :data

    def write(data)
      puts "data=#{data}"
      @data = data
    end
  end

  let :log do
    @testlog ||= TestLog.new
  end

  context 'creating a new instance' do
    it 'creates a new instance with a message' do
      expect{ Cyclid::API::Plugins::Log.new(message: 'this is a message') }.to_not raise_error
    end

    it 'fails if no message is given' do
      expect{ Cyclid::API::Plugins::Log.new }.to raise_error
    end
  end

  context 'performing an action' do
    it 'logs a message with no context data' do
      plugin = nil
      expect do
        plugin = Cyclid::API::Plugins::Log.new(message: 'this is a message')
      end.to_not raise_error
      expect{ plugin.prepare(transport: nil, ctx: nil) }.to_not raise_error
      expect(plugin.perform(log)).to be true
      expect(log.data).to eq('this is a message')
    end

    it 'logs a message with context data' do
      plugin = nil
      expect do
        plugin = Cyclid::API::Plugins::Log.new(message: 'this is a %{data}')
      end.to_not raise_error
      expect{ plugin.prepare(transport: nil, ctx: { data: 'message' }) }.to_not raise_error
      expect(plugin.perform(log)).to be true
      expect(log.data).to eq('this is a message')
    end
  end
end
