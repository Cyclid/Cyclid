# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for a single Organization document
      module Document
        def self.registered(app)
          include Errors::HTTPErrors

          # @method get_organizations_organization
          # @param [String] name Name of the organization.
          # @return [String] JSON represention of the requested organization.
          # Get a specific organization.
          app.get do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # Convert to a Hash and inject the Users data
            org_hash = org.serializable_hash
            org_hash['users'] = org.users.map(&:username)

            return org_hash.to_json
          end

          # @method put("/organizations/:name")
          # @param [String] name Name of the organization.
          # Modify a specific organization.
          app.put do
            authorized_for!(params[:name], Operations::WRITE)

            payload = json_request_body
            Cyclid.logger.debug payload

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            begin
              # Change the owner email if one is provided
              org['owner_email'] = payload['owner_email'] if payload.key? 'owner_email'

              # Change the users if a list of users was provided
              if payload.key? 'users'
                # Add each provided user to the Organization
                org.users = payload['users'].map do |username|
                  user = User.find_by(username: username)

                  halt_with_json_response(404, \
                                          INVALID_USER, \
                                          "user #{username} does not exist") \
                  if user.nil?

                  user
                end
              end

              org.save!
            rescue ActiveRecord::ActiveRecordError, \
                   ActiveRecord::UnknownAttributeError => ex

              Cyclid.logger.debug ex.message
              halt_with_json_response(400, INVALID_JSON, ex.message)
            end

            return json_response(NO_ERROR, "organization #{params['name']} updated")
          end
        end
      end
    end
  end
end 
