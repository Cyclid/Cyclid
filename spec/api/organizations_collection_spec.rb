require 'spec_helper'
require 'json'

describe 'the organizations collection' do
  include Rack::Test::Methods

  before :all do
    new_database
  end

  it 'requires authentication' do
    get '/organizations'
    expect(last_response.status).to eq(401)
  end

  it 'returns a list of organizations' do
    authorize 'admin', 'password'
    get '/organizations'
    expect(last_response.status).to eq(200)

    res_json = JSON.parse(last_response.body)
    expect(res_json).to eq([{"id"=>1, "name"=>"admins", "owner_email"=>"admins@example.com"}])
  end

  context 'creating a new organization' do
    it 'creates a new organization without any users' do
      new_org = {'name'=>'test',
                 'owner_email'=>'admin@example.com'}

      authorize 'admin', 'password'
      post_json '/organizations', new_org.to_json
      expect(last_response.status).to eq(200)
    end

    it 'fails to create a duplicate organization' do
      new_org = {'name'=>'test',
                 'owner_email'=>'admin@example.com'}

      authorize 'admin', 'password'
      post_json '/organizations', new_org.to_json
      expect(last_response.status).to eq(409)
    end

    it 'creates a new organization with valid users' do
      new_org = {'name'=>'test2',
                 'owner_email'=>'admin@example.com',
                 'users' => ['admin']}

      authorize 'admin', 'password'
      post_json '/organizations', new_org.to_json
      expect(last_response.status).to eq(200)
    end

    it 'fails to create a new organization with invalid users' do
      new_org = {'name'=>'test3',
                 'owner_email'=>'admin@example.com',
                 'users' => ['invalid']}

      authorize 'admin', 'password'
      post_json '/organizations', new_org.to_json
      expect(last_response.status).to eq(404)
    end

    it 'fails if no owner email is given' do
      new_org = {'name'=>'test4'}

      authorize 'admin', 'password'
      post_json '/organizations', new_org.to_json
      expect(last_response.status).to eq(400)
    end

    it 'fails if the JSON is invalid' do
      authorize 'admin', 'password'
      post_json '/organizations', 'this is not valid JSON' 
      expect(last_response.status).to eq(400)
    end
  end
end
