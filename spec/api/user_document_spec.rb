require 'spec_helper'
require 'json'

describe 'a user document' do
  include Rack::Test::Methods

  context 'without a test user' do
    before :all do
      new_database
    end

    it 'requires authentication' do
      get '/users/admin'
      expect(last_response.status).to eq(401)
    end

    it 'return a valid user' do
      authorize 'admin', 'password'
      get '/users/admin'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to eq('id' => 1,
                             'username' => 'admin',
                             'email' => 'admin@example.com',
                             'name' => 'Admin Test',
                             'organizations' => ['admins'])
    end

    it 'fails if the user does not exist' do
      authorize 'admin', 'password'
      get '/users/nobody'

      expect(last_response.status).to eq(404)
    end
  end

  context 'modifying a test user' do
    before :all do
      new_database

      # Create a test user
      new_user = { 'username' => 'test',
                   'email' => 'test@example.com',
                   'name' => 'Test Test',
                   'new_password' => 'password' }

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json
    end

    it 'changes the users email address' do
      modified_user = { 'email' => 'test@example.com' }

      authorize 'test', 'password'
      put_json '/users/test', modified_user.to_json
      expect(last_response.status).to eq(200)

      # Retrieve the user record and check that it changed
      authorize 'test', 'password'
      get '/users/test'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to eq('id' => 2,
                             'username' => 'test',
                             'email' => 'test@example.com',
                             'name' => 'Test Test',
                             'organizations' => [])
    end

    it 'changes the users name' do
      modified_user = { 'name' => 'Bob Dobbs' }

      authorize 'test', 'password'
      put_json '/users/test', modified_user.to_json
      expect(last_response.status).to eq(200)

      # Retrieve the user record and check that it changed
      authorize 'test', 'password'
      get '/users/test'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to eq('id' => 2,
                             'username' => 'test',
                             'email' => 'test@example.com',
                             'name' => 'Bob Dobbs',
                             'organizations' => [])
    end

    it 'changes the users password' do
      # rubocop:disable Metrics/LineLength
      modified_user = { 'password' => '$2a$10$/aFTQ84PZUPhiN8mz0q5l.Q18qMkJyXuQqva8PDrycfz9FnnbWldS' }
      # rubocop:enable Metrics/LineLength

      authorize 'test', 'password'
      put_json '/users/test', modified_user.to_json
      expect(last_response.status).to eq(200)
    end

    it 'changes the users password if one is given in plaintext' do
      modified_user = { 'new_passowrd' => 'password' }

      authorize 'test', 'password'
      put_json '/users/test', modified_user.to_json
      expect(last_response.status).to eq(200)
    end

    it 'fails if the new data is invalid' do
      authorize 'test', 'password'
      put_json '/users/test', 'this is not valid JSON'
      expect(last_response.status).to eq(400)
    end

    it 'deletes a user' do
      authorize 'admin', 'password'
      delete '/users/test'

      expect(last_response.status).to eq(200)
    end
  end
end
