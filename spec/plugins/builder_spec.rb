require 'spec_helper'

describe Cyclid::API::Plugins::Builder do
  it 'should have a human name' do
    expect(Cyclid::API::Plugins::Builder.human_name).to eq('builder')
  end

  context 'creating a new Builder plugin' do
    before :all do
      @builder = Cyclid::API::Plugins::Builder.new
    end

    it 'should not return an instance' do
      expect(@builder.get).to be_nil
    end

    it 'should not release an instance' do
      expect(@builder.release(nil, nil)).to be_nil
    end
  end
end

describe Cyclid::API::Plugins::BuildHost do
  context 'creating a new BuildHost' do
    before :all do
      args = { host: 'example.com',
               username: 'test',
               password: 'xxtestxx',
               extra: 'additional data' }
      @buildhost = Cyclid::API::Plugins::BuildHost.new(args)
    end

    it 'should be a sub-class of Hash' do
      expect(@buildhost).to be_a Hash
    end

    it 'should not have any default transports' do
      expect(@buildhost.transports).to match_array([])
    end

    it 'should return the connection information' do
      expect(@buildhost.connect_info).to match_array(['example.com', 'test', 'xxtestxx'])
    end

    it 'should store additional key/value pairs' do
      expect(@buildhost[:extra]).to eq('additional data')
    end

    it 'should return a copy of itself' do
      expect(@buildhost.context_info).to eq(@buildhost)
    end
  end
end
