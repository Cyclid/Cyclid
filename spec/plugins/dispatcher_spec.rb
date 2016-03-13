require 'spec_helper'

describe Cyclid::API::Plugins::Dispatcher do
  it 'should have a human name' do
    expect(Cyclid::API::Plugins::Dispatcher.human_name).to eq('dispatcher')
  end

  context 'creating a new Dispatcher plugin' do
    before :all do
      @dispatcher = Cyclid::API::Plugins::Dispatcher.new
    end
  end
end
