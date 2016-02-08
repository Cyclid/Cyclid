require 'oj'

# Top level module for all of the core Cyclid code.
module Cyclid
  # Controller for all Organization related API endpoints
  class OrganizationController < ControllerBase
    get '/organizations' do
      content_type :json

      organizations = Organization.all

      return organizations.to_json 
    end

    post '/organizations' do
      payload = json_request_body

      Cyclid.logger.debug payload

      halt 400 unless payload.key? 'name'

      organization = Organization.create(payload)
    end
  end

  # Register this controller
  Cyclid.controllers << OrganizationController
end
