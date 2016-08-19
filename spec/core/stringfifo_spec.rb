# frozen_string_literal: true
require 'spec_helper'

describe Cyclid::API::StringFIFO do
  context 'creating a new StringFIFO' do
    before :all do
      @fifo = Cyclid::API::StringFIFO.new
    end

    it 'should be empty' do
      expect(@fifo.string).to be_empty
    end

    it 'should have an alias for to_s' do
      expect(@fifo).to respond_to(:to_s)
      expect{ @fifo.to_s }.to_not raise_error
    end

    it 'should clear an empty buffer' do
      expect{ @fifo.clear }.to_not raise_error
    end
  end

  context 'writing and reading data' do
    before :all do
      @fifo = Cyclid::API::StringFIFO.new
    end

    it 'should remember data that has been written' do
      expect(@fifo.write('test')).to eq(4)
      expect(@fifo.read).to match(/\Atest\Z/)
    end

    it 'should append new data' do
      expect(@fifo.write('test')).to eq(8)
      expect(@fifo.string).to match(/\Atesttest\Z/)
    end

    it 'should read from the previous position' do
      expect(@fifo.read).to match(/\Atest\Z/)
    end

    it 'should clear the buffer' do
      expect{ @fifo.clear }.to_not raise_error
      expect(@fifo.string).to be_empty
    end

    it 'should read the length of data requested' do
      expect(@fifo.write('q' * 100)).to eq(100)
      expect(@fifo.read(10)).to match(/\Aqqqqqqqqqq\Z/)
      expect(@fifo.string).to eq('q' * 100)
    end
  end
end
