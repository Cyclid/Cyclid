# frozen_string_literal: true
require 'spec_helper'

new_database

describe 'the API root' do
  include Rack::Test::Methods

  it 'returns nothing' do
    get '/'
    expect(last_response.status).to eq(404)
  end
end
