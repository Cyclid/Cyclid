# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Controller for all Organization related API endpoints
    class OrganizationController < ControllerBase
      get '/organizations' do
        authenticate!

        orgs = Organization.all
        return orgs.to_json
      end

      get '/organizations/:name' do
        authenticate!

        org = Organization.find_by(name: params[:name])
        halt_with_json_response(404, INVALID_ORG,'organization does not exist') \
          if org.nil?

        # Convert to a Hash and inject the Users data
        org_hash = org.serializable_hash
        org_hash['users'] = org.users.map{ |user| user.username }

        return org_hash.to_json
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

          org = Organization.new
          org['name'] = payload['name']
          org['owner_email'] = payload['owner_email']

          # Add each provided user to the Organization
          org.users = payload['users'].map do |username|
            User.find_by(username: username)
          end

          org.save!
        rescue ActiveRecord::ActiveRecordError, \
               ActiveRecord::UnknownAttributeError => ex

          Cyclid.logger.debug ex.message
          halt_with_json_response(400, INVALID_JSON, ex.message)
        end

        return json_response(NO_ERROR, "organization #{payload['name']} created")
      end
    end

    # Register this controller
    Cyclid.controllers << OrganizationController
  end
end
