require 'oj'

# Top level module for all of the core Cyclid code.
module Cyclid
  # Controller for all Organization related API endpoints
  class OrganizationController < Sinatra::Base
    get '/organizations' do
      content_type :json

      organizations = Organization.all

      return organizations.to_json 
    end

    post '/organizations' do

      # Parse the JSON from the request
      begin
        request.body.rewind
        payload = Oj.load request.body.read
      rescue
        halt 400
      end

      Cyclid.logger.debug payload

      halt 400 unless payload.key? 'name'

      organization = Organization.create(payload)
    end
  end

  # Register this controller
  Cyclid.controllers << OrganizationController
end
