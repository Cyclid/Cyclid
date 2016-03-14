# rubocop:disable Style/GlobalVars
require 'spec_helper'
require 'json'
require 'yaml'

# Some helpers to mock out a Rack request
class TestBody
  def initialize(body)
    @body = body
  end

  def rewind
  end

  def read
    @body
  end
end

class TestRequest
  attr_reader :body, :content_type

  def initialize(body, content_type)
    @body = TestBody.new(body)
    @content_type = content_type
  end
end

describe Cyclid::API::APIHelpers do
  include Cyclid::API::APIHelpers
  # Required to get halt_with_json_response; not tested here
  include Cyclid::API::AuthHelpers

  def request
    $request
  end

  def halt(code, message)
    json = JSON.load(message)
    raise "#{code}:#{json['description']}"
  end

  describe '.parse_request_body' do
    context 'when given a valid JSON body' do
      it 'can parse an application/json body' do
        # Mock the Sinatra request
        body = { 'a' => 1, 'b' => 2 }
        $request = TestRequest.new(body.to_json, 'application/json')

        parsed = nil
        expect{ parsed = parse_request_body }.to_not raise_error
        expect(parsed).to eq body
      end

      it 'can parse a text/json body' do
        body = { 'a' => 1, 'b' => 2 }
        $request = TestRequest.new(body.to_json, 'text/json')

        parsed = nil
        expect{ parsed = parse_request_body }.to_not raise_error
        expect(parsed).to eq body
      end
    end

    context 'when given a valid YAML body' do
      it 'can parse an application/x-yaml body' do
        body = { 'a' => 1, 'b' => 2 }
        $request = TestRequest.new(body.to_yaml, 'application/x-yaml')

        parsed = nil
        expect{ parsed = parse_request_body }.to_not raise_error
        expect(parsed).to eq body
      end

      it 'can parse an text/x-yaml body' do
        body = { 'a' => 1, 'b' => 2 }
        $request = TestRequest.new(body.to_yaml, 'text/x-yaml')

        parsed = nil
        expect{ parsed = parse_request_body }.to_not raise_error
        expect(parsed).to eq body
      end
    end

    context 'when given an invalid JSON body' do
      it 'fails with an error' do
        body = 'this is not valid JSON'
        $request = TestRequest.new(body, 'application/json')

        expect{ parse_request_body }.to \
          raise_error('400:expected true at line 1, column 2 [parse.c:148]')
      end
    end

    context 'when given an invalid YAML body' do
      it 'fails with an error' do
        body = 'this is not valid YAML'
        $request = TestRequest.new(body, 'application/x-yaml')

        expect{ parse_request_body }.to raise_error('400:request body is invalid')
      end
    end

    context 'when given an empty body' do
      it 'fails with an error' do
        body = ''
        $request = TestRequest.new(body, 'application/json')

        expect{ parse_request_body }.to raise_error('400:request body can not be empty')
      end
    end

    context 'when given an invalid content-type' do
      it 'fails with an error' do
        body = 'this is not valid YAML'
        $request = TestRequest.new(body, 'test')

        expect{ parse_request_body }.to raise_error('415:unsupported content type test')
      end
    end
  end
end
