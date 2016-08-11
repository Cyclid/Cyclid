# Copyright 2016 Liqwyd Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for the Organization collection
      # @api REST
      module Collection
        # @!group Organizations

        # @!method get_organizations
        # @overload GET /organizations
        # @macro rest
        # Get all of the organizations.
        # @return List of organizations
        # @example Get a list of organizations
        #   GET /organizations => [{"id": 1, "name": "example", "owner_email": "admin@example.com"}]
        # @see get_organizations_organization

        # @!method post_organizations(body)
        # @overload POST /organizations
        # @macro rest
        # Create a new organization.
        # @param [JSON] body New organization
        # @option body [String] name Name of the new organization
        # @option body [String] owner_email Email address of the organization owner
        # @option body [Array<String>] users ([]) List of users to add to the organization
        # @return [200] Organization was created successfully
        # @return [404] A user in the list of members does not exist
        # @return [409] An organization with that name already exists
        # @example Create a new organization with user1 & user2 as members
        #   POST /organizations <= {"name": "example",
        #                           "owner_email": "admin@example.com",
        #                           "users": ["user1", "user2"]}
        #                           ***
        # @example Create a new organization with no users as members
        #   POST /organizations <= {"name": "example",
        #                           "owner_email": "admin@example.com"}
        #                           ***

        # @!endgroup

        # Sinatra callback
        # @private
        def self.registered(app)
          include Errors::HTTPErrors
          include Constants

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
