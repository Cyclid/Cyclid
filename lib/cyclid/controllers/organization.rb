require 'oj'
require 'warden'

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Controller for all Organization related API endpoints
    class OrganizationController < ControllerBase
      get '/organizations' do
        authenticate!

        organizations = Organization.all
        return organizations.to_json
      end

      post '/organizations' do
        authenticate!

        payload = json_request_body
        Cyclid.logger.debug payload

        begin
          halt_with_json_response(409, \
            DUPLICATE, \
            'An organization with that name already exists') \
          if Organization.exists?(name: payload['name'])

          organization = Organization.new(payload)
          organization.save!
        rescue ActiveRecord::ActiveRecordError, \
               ActiveRecord::UnknownAttributeError => ex

          Cyclid.logger.debug ex.message
          halt_with_json_response(400, INVALID_JSON, ex.message)
        end
      end
    end

    # Register this controller
    Cyclid.controllers << OrganizationController
  end
end
