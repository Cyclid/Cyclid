require 'spec_helper'

describe Cyclid::API::Plugins::Provisioner do
  it 'should have a human name' do
    expect(Cyclid::API::Plugins::Provisioner.human_name).to eq('provisioner')
  end

  context 'creating a new Provisioner plugin' do
    before :all do
      @provisioner = Cyclid::API::Plugins::Provisioner.new
    end

    it 'should not prepare a host' do
      expect(@provisioner.prepare(nil, nil)).to be false
    end
  end
end
