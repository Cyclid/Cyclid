require 'spec_helper'
require 'json'

describe 'an organization document' do
  include Rack::Test::Methods

  before :all do
    new_database
  end

  it 'requires authentication' do
    get '/organizations/admins'
    expect(last_response.status).to eq(401)
  end

  it 'return a valid organization' do
    authorize 'admin', 'password'
    get '/organizations/admins'
    expect(last_response.status).to eq(200)

    res_json = JSON.parse(last_response.body)
    expect(res_json).to eq('id' => 1,
                           'name' => 'admins',
                           'owner_email' => 'admins@example.com',
                           'users' => ['admin'])
  end

  it 'fails if the organizations does not exist' do
    authorize 'admin', 'password'
    get '/organizations/test'

    expect(last_response.status).to eq(404)
  end

  context 'modifying an organization' do
    it 'changes the owner email address' do
      modified_org = { 'owner_email' => 'test@example.com' }

      authorize 'admin', 'password'
      put_json '/organizations/admins', modified_org.to_json
      expect(last_response.status).to eq(200)

      # Retrieve the organization record and check that it changed
      authorize 'admin', 'password'
      get '/organizations/admins'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)

      expect(res_json).to eq('id' => 1,
                             'name' => 'admins',
                             'owner_email' => 'test@example.com',
                             'users' => ['admin'])
    end

    it 'adds a new user' do
      # Create a test user that isn't in the organization
      new_user = { 'username' => 'test',
                   'email' => 'test@example.com' }

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json
      expect(last_response.status).to eq(200)

      # Add the user to the organization
      modified_org = { 'users' => %w(admin test) }

      authorize 'admin', 'password'
      put_json '/organizations/admins', modified_org.to_json
      expect(last_response.status).to eq(200)

      # Retrieve the organization record and check that it changed
      authorize 'admin', 'password'
      get '/organizations/admins'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)

      expect(res_json).to eq('id' => 1,
                             'name' => 'admins',
                             'owner_email' => 'test@example.com',
                             'users' => %w(admin test))
    end

    it 'removes a user' do
      modified_org = { 'users' => ['admin'] }

      authorize 'admin', 'password'
      put_json '/organizations/admins', modified_org.to_json
      expect(last_response.status).to eq(200)

      # Retrieve the organization record and check that it changed
      authorize 'admin', 'password'
      get '/organizations/admins'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)

      expect(res_json).to eq('id' => 1,
                             'name' => 'admins',
                             'owner_email' => 'test@example.com',
                             'users' => ['admin'])
    end

    it 'does not add an invalid user' do
      modified_org = { 'users' => ['invalid'] }

      authorize 'admin', 'password'
      put_json '/organizations/admins', modified_org.to_json
      expect(last_response.status).to eq(404)
    end

    it 'fails if the new data is invalid' do
      authorize 'admin', 'password'
      put_json '/organizations/admins', 'this is not valid JSON'
      expect(last_response.status).to eq(400)
    end
  end
end
