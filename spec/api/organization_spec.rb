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
  end
end
