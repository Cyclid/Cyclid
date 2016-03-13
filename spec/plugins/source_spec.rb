require 'spec_helper'

describe Cyclid::API::Plugins::Source do
  it 'should have a human name' do
    expect(Cyclid::API::Plugins::Source.human_name).to eq('source')
  end

  context 'creating a new Source plugin' do
    before :all do
      @source = Cyclid::API::Plugins::Source.new
    end

    it 'should fail to check out' do
      expect(@source.checkout(nil, nil)).to be false
    end
  end
end
