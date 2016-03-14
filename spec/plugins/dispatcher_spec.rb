require 'spec_helper'

describe Cyclid::API::Plugins::Dispatcher do
  it 'should have a human name' do
    expect(Cyclid::API::Plugins::Dispatcher.human_name).to eq('dispatcher')
  end

  context 'creating a new Dispatcher plugin' do
    before :all do
      @dispatcher = Cyclid::API::Plugins::Dispatcher.new
    end

    it 'should not dispatch a job' do
      expect(@dispatcher.dispatch(nil, nil)).to be_nil
    end
  end
end

describe Cyclid::API::Plugins::Notifier::Base do
  before :all do
    @notifier = Cyclid::API::Plugins::Notifier::Base.new(nil, nil)
  end

  it 'should have a status= method' do
    expect(@notifier).to respond_to(:status=)
  end

  it 'should have an ended= method' do
    expect(@notifier).to respond_to(:ended=)
  end

  it 'should have a completion method' do
    expect(@notifier).to respond_to(:completion)
  end

  it 'should have a write method' do
    expect(@notifier).to respond_to(:write)
  end
end

describe Cyclid::API::Plugins::Notifier::Callback do
  before :all do
    @callback = Cyclid::API::Plugins::Notifier::Callback.new
  end

  it 'should have a completion method' do
    expect(@callback).to respond_to(:completion)
  end

  it 'should have a status_changed method' do
    expect(@callback).to respond_to(:status_changed)
  end

  it 'should have a log_write method' do
    expect(@callback).to respond_to(:log_write)
  end
end
