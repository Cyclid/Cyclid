# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::LogBuffer do
  context 'creating a new LogBuffer' do
    before :all do
      @buffer = Cyclid::API::LogBuffer.new
    end

    it 'should be empty' do
      expect(@buffer.log).to be_empty
    end

    it 'should not have any data to read' do
      expect(@buffer.read).to be_empty
    end

    it 'should write new data without a JobRecord' do
      expect{ @buffer.write('test') }.to_not raise_error
    end
  end

  context 'writing and reading data' do
    class TestRecord
      attr_accessor :log

      def save!
        true
      end
    end

    before :all do
      @record = TestRecord.new
      @buffer = Cyclid::API::LogBuffer.new(@record)
    end

    it 'should write data to the JobRecord' do
      expect{ @buffer.write('test') }.to_not raise_error
      expect(@record.log).to match(/\Atest\Z/)
    end

    it 'should allow data to be read from the log' do
      expect(@buffer.read).to match(/\Atest\Z/)
    end

    it 'should return en empty string when there is no new data to read' do
      expect(@buffer.read).to be_empty
    end

    it 'should return the complete log' do
      expect(@buffer.log).to match(/\Atest\Z/)
    end
  end
end
