require 'spec_helper'
require 'json'

describe 'the users collection' do
  include Rack::Test::Methods

  before :all do
    new_database
  end

  it 'requires authentication' do
    get '/users'
    expect(last_response.status).to eq(401)
  end

  it 'returns a list of users' do
    authorize 'admin', 'password'
    get '/users'
    expect(last_response.status).to eq(200)

    res_json = JSON.parse(last_response.body)
    expect(res_json).to eq([{'id'=>1,'username'=>'admin','email'=>'admin@example.com'}])
  end

  context 'creating a new user' do
    it 'creates a new user without a password or secret' do
      new_user = {'username'=>'test',
                  'email'=>'test@example.com'}

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json
      expect(last_response.status).to eq(200)
    end

    it 'fails to create a duplicate user' do
      new_user = {'username'=>'test',
                  'email'=>'test@example.com'}

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json
      expect(last_response.status).to eq(409)
    end

    it 'creates a new user with a password and secret' do
      new_user = {'username'=>'test2',
                  'email'=>'test2@example.com',
                  'password'=>'$2a$10$/aFTQ84PZUPhiN8mz0q5l.Q18qMkJyXuQqva8PDrycfz9FnnbWldS',
                  'secret'=>'aasecret55'}

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json
      expect(last_response.status).to eq(200)
    end

    it 'encodes a password if one is given in plaintext' do
      new_user = {'username'=>'test3',
                  'email'=>'test3@example.com',
                  'new_password'=>'password'}

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json
      expect(last_response.status).to eq(200)
    end

    it 'fails if an email address is not given' do
      new_user = {'username'=>'test4'}

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json
      expect(last_response.status).to eq(400)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to eq({'id'=>2,'description'=>"Validation failed: Email can't be blank"})
    end

    it 'fails if the JSON is invalid' do
      authorize 'admin', 'password'
      post_json '/users', 'this is not valid JSON' 
      expect(last_response.status).to eq(400)
    end
  end
end
