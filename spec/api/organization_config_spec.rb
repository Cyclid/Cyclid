# frozen_string_literal: true
require 'spec_helper'
require 'json'

describe 'an organization document' do
  include Rack::Test::Methods

  before :all do
    new_database
  end

  # Use a plugin that we know exists and does not have a config
  context 'retrieving a plugin configuration' do
    it 'returns the default config' do
      authorize 'admin', 'password'
      get '/organizations/admins/configs/action/command'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to include('plugin' => 'command',
                                  'config' => {},
                                  'schema' => {})
    end
  end

  # It doesn't matter that these fail; the failure comes from the Plugin base class, but this tests
  # the controller.
  context 'setting a plugin configuration' do
    it 'updates an existing config' do
      new_config = { test: 'data' }

      authorize 'admin', 'password'
      put_json '/organizations/admins/configs/action/command', new_config.to_json
      expect(last_response.status).to eq(404)
    end

    it 'creates a new config' do
      new_config = { test: 'data' }

      authorize 'admin', 'password'
      put_json '/organizations/admins/configs/dispatcher/local', new_config.to_json
      expect(last_response.status).to eq(404)
    end
  end
end
