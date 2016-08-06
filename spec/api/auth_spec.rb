require 'spec_helper'
require 'json'

describe 'an API token' do
  include Rack::Test::Methods

  context 'with a valid user' do
    before :all do
      new_database
    end

    it 'requires authentication' do
      post_json '/token/admin', '{}'
      expect(last_response.status).to eq(401)
    end

    it 'returns an API token' do
      authorize 'admin', 'password'
      post_json '/token/admin', '{}'
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to match('token' => /\A(.*)\.(.*)\.(.*)\z/)
    end

    it 'honors valid claims in the token' do
      nbf = 1577836800
      exp = 1893456000
      claims = {'nbf' => nbf, 'exp' => exp}

      authorize 'admin', 'password'
      post_json '/token/admin', claims.to_json
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to match('token' => /\A(.*)\.(.*)\.(.*)\z/)

      # Decode the 'claims' section of the token
      match = res_json['token'].match /\A(.*)\.(.*)\.(.*)\z/
      res_header = match[1]
      res_claims = match[2]
      res_signature = match[3]

      # nbf & exp should be the same as the request
      claims = JSON.parse(Base64.decode64(res_claims))
      expect(claims).to eq('nbf' => nbf, 'exp' => exp, 'sub' => 'admin')
    end

    it 'sets the exp claim if none is given' do
      nbf = 1577836800
      claims = {'nbf' => nbf}

      authorize 'admin', 'password'
      post_json '/token/admin', claims.to_json
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to match('token' => /\A(.*)\.(.*)\.(.*)\z/)

      # Decode the 'claims' section of the token
      match = res_json['token'].match /\A(.*)\.(.*)\.(.*)\z/
      res_header = match[1]
      res_claims = match[2]
      res_signature = match[3]

      # nbf & exp should be the same as the request
      claims = JSON.parse(Base64.decode64(res_claims))
      expect(claims).to match('nbf' => nbf, 'exp' => a_kind_of(Integer), 'sub' => 'admin')

    end

    it 'strips claims' do
      claims = {'iss' => 'test',
                'aud' => 'test',
                'jti' => 'test',
                'iat' => 'test',
                'sub' => 'test'}

      authorize 'admin', 'password'
      post_json '/token/admin', claims.to_json
      expect(last_response.status).to eq(200)

      res_json = JSON.parse(last_response.body)
      expect(res_json).to match('token' => /\A(.*)\.(.*)\.(.*)\z/)

      # Decode the 'claims' section of the token
      match = res_json['token'].match /\A(.*)\.(.*)\.(.*)\z/
      res_header = match[1]
      res_claims = match[2]
      res_signature = match[3]

      # All of the claims given in the initial request should have been
      # stripped
      claims = JSON.parse(Base64.decode64(res_claims))
      expect(claims).to match('sub' => 'admin', 'exp' => a_kind_of(Integer))
    end
  end
end
