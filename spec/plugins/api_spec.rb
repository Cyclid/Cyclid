# frozen_string_literal: true
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
    expect(@methods.post(nil, nil)).to be false
  end

  it 'should return a failure for the put method' do
    authorize 'admin', 'password'
    expect(@methods.put(nil, nil)).to be false
  end

  it 'should return a failure for the delete method' do
    authorize 'admin', 'password'
    expect(@methods.delete(nil, nil)).to be false
  end
end

describe Cyclid::API::Plugins::ApiExtension::Controller do
  module APIPlugin
    # Create a stub plugin implementation
    module TestMethods
      include Cyclid::API::Plugins::ApiExtension::Methods

      def controller_plugin
        Cyclid::API::Plugins::Api
      end
    end

    class TestController < Cyclid::API::Plugins::Api
      def self.controller
        return Cyclid::API::Plugins::ApiExtension::Controller.new(TestMethods)
      end
    end

    # Create a Sinatra application to register the plugin controller with
    require 'sinatra/base'
    require 'sinatra/namespace'

    class TestApp < Cyclid::API::ControllerBase
      register Sinatra::Namespace
      namespace '/test/:name' do
        ctrl = TestController.controller
        register ctrl
        helpers ctrl.plugin_methods
      end
    end
  end

  # Some Rack::Test boilerplate
  include Rack::Test::Methods

  def app
    APIPlugin::TestApp
  end

  before :all do
    new_database
  end

  it 'requires authentication for the GET method' do
    get '/test/admins'
    expect(last_response.status).to eq(401)
  end

  it 'returns "not implemented" for the GET method' do
    authorize 'admin', 'password'
    get '/test/admins'
    expect(last_response.status).to eq(405)
  end

  it 'requires authentication for the POST method' do
    post_json '/test/admins', '{}'
    expect(last_response.status).to eq(401)
  end

  it 'returns "not implemented" for the POST method' do
    authorize 'admin', 'password'
    post_json '/test/admins', '{}'
    expect(last_response.status).to eq(405)
  end

  it 'requires authentication for the PUT method' do
    put_json '/test/admins', '{}'
    expect(last_response.status).to eq(401)
  end

  it 'returns "not implemented" for the PUT method' do
    authorize 'admin', 'password'
    put_json '/test/admins', '{}'
    expect(last_response.status).to eq(405)
  end

  it 'requires authentication for the DELETE method' do
    delete '/test/admins'
    expect(last_response.status).to eq(401)
  end

  it 'returns "not implemented" for the DELETE method' do
    authorize 'admin', 'password'
    delete '/test/admins'
    expect(last_response.status).to eq(405)
  end
end
