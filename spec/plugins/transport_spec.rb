require 'spec_helper'

describe Cyclid::API::Plugins::Transport do
  it 'should have a human name' do
    expect(Cyclid::API::Plugins::Transport.human_name).to eq('transport')
  end

  context 'creating a new Transport plugin' do
    before :all do
      @transport = Cyclid::API::Plugins::Transport.new
    end
  end
end
