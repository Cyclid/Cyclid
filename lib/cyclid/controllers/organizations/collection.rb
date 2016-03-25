# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for the Organization collection
      module Collection
        # Sinatra callback
        def self.registered(app)
          include Errors::HTTPErrors
          include Constants

          # @macro [attach] sinatra.get
          #   @overload get "$1"
          # @method get_organizationss
          # @return [String] JSON represention of all the organizations.
          # Get all of the organizations.
          app.get do
            authorized_admin!(Operations::READ)

            # Retrieve the organization data in a form we can more easily
            # manipulate so that we can sanitize it
            orgs = Organization.all_as_hash

            # Remove any sensitive data
            orgs.map! do |org|
              sanitize_organization(org)
            end

            return orgs.to_json
          end

          # @macro [attach] sinatra.post
          #   @overload post "$1"
          # @method post_organizations
          # Create a new organization.
          app.post do
            authorized_admin!(Operations::ADMIN)

            payload = parse_request_body
            Cyclid.logger.debug payload

            begin
              halt_with_json_response(409, \
                                      DUPLICATE, \
                                      'An organization with that name already exists') \
              if Organization.exists?(name: payload['name'])

              org = Organization.new
              org['name'] = payload['name']
              org['owner_email'] = payload['owner_email']

              # Generate an RSA key-pair and a Salt
              key = OpenSSL::PKey::RSA.new(RSA_KEY_LENGTH)

              org['rsa_private_key'] = key.to_der
              org['rsa_public_key'] = key.public_key.to_der

              org['salt'] = SecureRandom.hex(32)

              # Add each provided user to the Organization
              users = payload['users'] || []

              org.users = users.map do |username|
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
