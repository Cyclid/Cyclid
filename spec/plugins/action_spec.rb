require 'spec_helper'

describe Cyclid::API::Plugins::Action do
  it 'should have a human name' do
    expect(Cyclid::API::Plugins::Action.human_name).to eq('action')
  end

  context 'creating a new Action plugin' do
    before :all do
      @action = Cyclid::API::Plugins::Action.new
    end

    it 'should prepare' do
      expect{ @action.prepare }.to_not raise_error
    end

    it 'should not perform any action' do
      expect(@action.perform(nil)).to be_nil
    end
  end
end
