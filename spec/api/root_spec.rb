require 'spec_helper'

describe 'the API root' do
  include Rack::Test::Methods

  it 'returns nothing' do
    get '/'
    expect(last_response.status).to eq(404)
  end
end
