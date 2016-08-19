# frozen_string_literal: true
require 'spec_helper'
require 'json'

describe 'an organization stage' do
  include Rack::Test::Methods

  it 'requires authentication' do
    get '/organizations/admins/stages'
    expect(last_response.status).to eq(401)
  end

  context 'with no stages defined' do
    before :all do
      new_database
    end

    it 'returns an empty list' do
      authorize 'admin', 'password'
      get '/organizations/admins/stages'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to match_array([])
    end
  end

  context 'creating a stage' do
    before :all do
      new_database
    end

    it 'creates a stage with an empty set of steps' do
      new_stage = { name: 'test', steps: [] }

      authorize 'admin', 'password'
      post_json '/organizations/admins/stages', new_stage.to_json
      expect(last_response.status).to eq(200)
    end

    it 'fails to create a stage with the same name and version' do
      new_stage = { name: 'test', steps: [] }

      authorize 'admin', 'password'
      post_json '/organizations/admins/stages', new_stage.to_json
      expect(last_response.status).to eq(409)
    end

    it 'creates a new version of the stage' do
      new_stage = { name: 'test', version: '9.9.9', steps: [] }

      authorize 'admin', 'password'
      post_json '/organizations/admins/stages', new_stage.to_json
      expect(last_response.status).to eq(200)
    end

    it 'fails to create a stage without any steps' do
      new_stage = { name: 'test2' }

      authorize 'admin', 'password'
      post_json '/organizations/admins/stages', new_stage.to_json
      expect(last_response.status).to eq(400)
    end

    it 'creates a stage with a set of steps' do
      new_stage = { name: 'test3', steps: [{ action: 'command', cmd: '/bin/true' }] }

      authorize 'admin', 'password'
      post_json '/organizations/admins/stages', new_stage.to_json
      expect(last_response.status).to eq(200)
    end
  end

  context 'with stages defined' do
    before :all do
      new_database

      new_stage1 = { name: 'test', steps: [] }
      authorize 'admin', 'password'
      post_json '/organizations/admins/stages', new_stage1.to_json

      new_stage2 = { name: 'test', version: '9.9.9', steps: [] }
      authorize 'admin', 'password'
      post_json '/organizations/admins/stages', new_stage2.to_json
    end

    it 'returns an list of stages' do
      authorize 'admin', 'password'
      get '/organizations/admins/stages'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to match_array([{ 'name' => 'test',
                                         'version' => '0.0.1',
                                         'steps' => [] },
                                       { 'name' => 'test',
                                         'version' => '9.9.9',
                                         'steps' => [] }])
    end

    it 'returns the stage' do
      authorize 'admin', 'password'
      get '/organizations/admins/stages/test'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to match_array([{ 'name' => 'test',
                                         'version' => '0.0.1',
                                         'steps' => [] },
                                       { 'name' => 'test',
                                         'version' => '9.9.9',
                                         'steps' => [] }])
    end

    it 'returns the given version of the stage' do
      authorize 'admin', 'password'
      get '/organizations/admins/stages/test/9.9.9'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to match_array('name' => 'test',
                                      'version' => '9.9.9',
                                      'steps' => [])
    end
  end
end
