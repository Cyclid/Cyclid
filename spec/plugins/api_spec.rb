require 'spec_helper'

describe Cyclid::API::Plugins::Api do
  it 'should have a human name' do
    expect(Cyclid::API::Plugins::Api.human_name).to eq('api')
  end

  it 'returns a new controller instance' do
    expect{ Cyclid::API::Plugins::Api.controller }.to_not raise_error
  end
end

describe Cyclid::API::Plugins::ApiExtension::Methods do
  include Rack::Test::Methods

  class TestMethods
    include Cyclid::API::Plugins::ApiExtension::Methods

    def authorize(*_args)
      true
    end

    def return_failure(*_args)
      false
    end
  end

  before :all do
    @methods = TestMethods.new
  end

  it 'should return a failure for the get method' do
    authorize 'admin', 'password'
    expect(@methods.get(nil, nil)).to be false
  end

  it 'should return a failure for the post method' do
    authorize 'admin', 'password'
    expect(@methods.post(nil, nil, nil)).to be false
  end

  it 'should return a failure for the put method' do
    authorize 'admin', 'password'
    expect(@methods.put(nil, nil, nil)).to be false
  end

  it 'should return a failure for the delete method' do
    authorize 'admin', 'password'
    expect(@methods.delete(nil, nil)).to be false
  end
end

describe Cyclid::API::Plugins::ApiExtension::Helpers do
  include Rack::Test::Methods

  class TestHelpers
    include Cyclid::API::Plugins::ApiExtension::Helpers

    def headers
      {}
    end
  end

  before :all do
    @helpers = TestHelpers.new

    def authorized_for!(_name, _operation)
      true
    end
  end

  it 'authorizes a user for a get' do
    authorize 'admin', 'password'
    expect(@helpers.authorize('get')).to be true
  end

  it 'authorizes a user for a post' do
    authorize 'admin', 'password'
    expect(@helpers.authorize('post')).to be true
  end

  it 'authorizes a user for a put' do
    authorize 'admin', 'password'
    expect(@helpers.authorize('put')).to be true
  end

  it 'authorizes a user for a delete' do
    authorize 'admin', 'password'
    expect(@helpers.authorize('delete')).to be true
  end

  it 'extracts HTTP headers' do
    expect(@helpers.http_headers([%w(HTTP_HEADER test),
                                  %w(NOT_A_HEADER xxx)])).to match_array([%w(Header test)])
  end
end
