require 'spec_helper'

describe 'authentication strategies' do
  include Rack::Test::Methods

  before :all do
    new_database
  end

  it 'authenticates with HTTP basic authentication' do
    user_pass = 'admin:password'
    authorization = "Basic #{Base64.encode64(user_pass)}"

    get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
    expect(last_response.status).to eq(200)
  end

  it 'authenticates with HMAC authentication' do
    user = 'admin'
    secret = 'aasecret55'

    # Create a new HMAC signer and sign our request
    signer = Cyclid::HMAC::Signer.new
    nonce = SecureRandom.hex
    headers = signer.sign_request('/organizations',
                                  secret,
                                  auth_header_format: '%{auth_scheme} %{username}:%{signature}',
                                  username: user,
                                  nonce: nonce)

    headers_hash = headers[0]
    get '/organizations', {}, 'HTTP_AUTHORIZATION' => headers_hash['Authorization'],
                              'HTTP_X_HMAC_NONCE' => headers_hash['X-HMAC-Nonce'],
                              'HTTP_DATE' => headers_hash['Date']
    expect(last_response.status).to eq(200)
  end

  it 'authenticates with token based authentication' do
    authorization = 'Token admin:aasecret55'

    get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
    expect(last_response.status).to eq(200)
  end
end
