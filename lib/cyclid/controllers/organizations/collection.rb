# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for the Organization collection
      module Collection
        def self.registered(app)
          include Errors::HTTPErrors

          # @macro [attach] sinatra.get
          #   @overload get "$1"
          # @method get_organizationss
          # @return [String] JSON represention of all the organizations.
          # Get all of the organizations.
          app.get do
            authorized_admin!(Operations::READ)

            orgs = Organization.all
            return orgs.to_json
          end

          # @macro [attach] sinatra.post
          #   @overload post "$1"
          # @method post_organizations
          # Create a new organization.
          app.post do
            authorized_admin!(Operations::ADMIN)

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
                user = User.find_by(username: username)

                halt_with_json_response(404, \
                                        INVALID_USER, \
                                        "user #{user} does not exist") \
                if user.nil?

                user
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
      end
    end
  end
end
