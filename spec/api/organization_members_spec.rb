# frozen_string_literal: true
require 'spec_helper'
require 'json'

describe 'an organization member' do
  include Rack::Test::Methods

  before :all do
    new_database
  end

  context 'retrieving a member' do
    it 'returns a valid sanitized organization member' do
      authorize 'admin', 'password'
      get '/organizations/admins/members/admin'
      expect(last_response.status).to eq(200)

      # The response _should not_ include the users password, secret, or any foreign keys
      res_json = JSON.parse(last_response.body)
      expect(res_json).to eq('id' => 1,
                             'username' => 'admin',
                             'email' => 'admin@example.com',
                             'name' => 'Admin Test',
                             'permissions' => {
                               'admin' => true,
                               'write' => true,
                               'read' => true
                             })
    end

    it 'fails to return an invalid organization member' do
      authorize 'admin', 'password'
      get '/organizations/admins/members/invalid'
      expect(last_response.status).to eq(404)
    end
  end

  context 'modifying a member' do
    it 'changes the users read permission' do
      new_perms = { permissions: { read: false } }

      authorize 'admin', 'password'
      put_json '/organizations/admins/members/admin', new_perms.to_json
      expect(last_response.status).to eq(200)

      # Retrieve the memmber and check that it changed
      authorize 'admin', 'password'
      get '/organizations/admins/members/admin'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to eq('id' => 1,
                             'username' => 'admin',
                             'email' => 'admin@example.com',
                             'name' => 'Admin Test',
                             'permissions' => {
                               'admin' => true,
                               'write' => true,
                               'read' => false
                             })
    end

    it 'does not fail if new permissions are not given' do
      new_perms = {}

      authorize 'admin', 'password'
      put_json '/organizations/admins/members/admin', new_perms.to_json
      expect(last_response.status).to eq(200)
    end

    it 'ignores unknown permissions' do
      new_perms = { permissions: { invalid: true } }

      authorize 'admin', 'password'
      put_json '/organizations/admins/members/admin', new_perms.to_json
      expect(last_response.status).to eq(200)
    end

    it 'fails if the new data is invalid' do
      authorize 'admin', 'password'
      put_json '/organizations/admins/members/admin', 'this is not valid JSON'
      expect(last_response.status).to eq(400)
    end
  end
end
