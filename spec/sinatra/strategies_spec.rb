require 'spec_helper'

describe 'authentication strategies' do
  include Rack::Test::Methods

  before :all do
    new_database
  end

  context 'using HTTP Basic authentication' do
    it 'authenticates successfully with a valid username & password' do
      user_pass = 'admin:password'
      authorization = "Basic #{Base64.encode64(user_pass)}"

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
      expect(last_response.status).to eq(200)
    end

    it 'fails to authenticate with an invalid username' do
      user_pass = 'nobody:password'
      authorization = "Basic #{Base64.encode64(user_pass)}"

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
      expect(last_response.status).to eq(401)
    end

    it 'fails to authenticate with an invalid password' do
      user_pass = 'admin:abcdefgh'
      authorization = "Basic #{Base64.encode64(user_pass)}"

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
      expect(last_response.status).to eq(401)
    end

    it 'fails with an invalid authorization header' do
      user_pass = 'invalid'
      authorization = "Basic #{Base64.encode64(user_pass)}"

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
      expect(last_response.status).to eq(401)
    end
  end

  context 'using HMAC authentication' do
    it 'authenticates with a valid HMAC signature' do
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

    it 'fails to authenticate with an invalid username' do
      user = 'nobody'
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
      expect(last_response.status).to eq(401)
    end

    it 'fails to authenticate with an invalid signing secret' do
      user = 'admin'
      secret = 'abcdefgh'

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
      expect(last_response.status).to eq(401)
    end

    it 'fails to authenticate when the nonce is missing' do
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
                                'HTTP_DATE' => headers_hash['Date']
      expect(last_response.status).to eq(401)
    end

    it 'fails to authenticate when the date is missing' do
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
                                'HTTP_X_HMAC_NONCE' => headers_hash['X-HMAC-Nonce']
      expect(last_response.status).to eq(401)
    end

    it 'does not allow a replay of a valid authentication' do
      # This is a valid HMAC signature at the time it was generated
      authorization = 'HMAC admin:995a0c2dc234b75027bd1859d4847ffa4316b5c2'
      nonce = '7bb74f415e68e6ba46306a6821ed2fc1'
      date = 'Sun, 20 Mar 2016 12:47:23 GMT'

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization,
                                'HTTP_X_HMAC_NONCE' => nonce,
                                'HTTP_DATE' => date
      expect(last_response.status).to eq(401)
    end
  end

  context 'using token authentication' do
    let :token do
      authorize 'admin', 'password'
      post_json '/token/admin', '{}'

      res_json = JSON.parse(last_response.body)
      res_json['token']
    end

    it 'authenticates successfully with a valid username & token' do
      authorization = "Token admin:#{token}"

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
      expect(last_response.status).to eq(200)
    end

    it 'fails to authenticate with an invalid username' do
      authorization = "Token nobody:#{token}"

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
      expect(last_response.status).to eq(401)
    end

    it 'fails to authenticate with an invalid token' do
      authorization = 'Token admin:abcdefgh'

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
      expect(last_response.status).to eq(401)
    end

    it 'fails to authenticate with an expired token' do
      #{"exp": 1451606400,"sub": "admin"}
      authorization = 'Token admin:eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0NTE2MDY0MDAsInN1YiI6ImFkbWluIn0.w92ekihhF_cei7gem0HWyt2xAc441nAR4KAJq8ttCRY'

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
      expect(last_response.status).to eq(401)
    end

    it 'fails to authenticate with another users token' do
      authorization = 'Token admin:eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjE0OTIwODE1NzYsInN1YiI6Im5vYm9keSJ9.k1y_H8c19cIVkKURaujKI6PRMC3WYge_Ai29fTvejIU'

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
      expect(last_response.status).to eq(401)
    end

    it 'fails with an invalid authorization header' do
      authorization = 'Token invalid'

      get '/organizations', {}, 'HTTP_AUTHORIZATION' => authorization
      expect(last_response.status).to eq(401)
    end
  end
end
