# frozen_string_literal: true
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
      # API endpoints for a single Organization document
      # @api REST
      module Document
        # @!group Organizations

        # @!method get_organizations_organization
        # @overload GET /organizations/:organization
        # @macro rest
        # @param [String] organization Name of the organization.
        # Get a specific organization. The RSA public key is in Base64 encoded
        # DER format, and can be used to encrypt secrets that can be
        # decrypted only by the server.
        # @return The organization object.
        # @return [404] The requested organization does not exist.
        # @example Get the 'example' organization
        #   GET /organizations/example => [{"id": 1,
        #                                   "name": "example",
        #                                   "owner_email": "admin@example.com",
        #                                   "users": ["user1", "user2"],
        #                                   "public_key": "<RSA public key>"}]
        # @see get_organizations

        # @!method put_organizations(body)
        # @overload PUT /organizations/:organization
        # @macro rest
        # @param [String] organization Name of the organization.
        # Modify an organization. The organizations name or public key can not
        # be changed.
        # If a list of users is provided, the current list will be *replaced*,
        # so clients should first retrieve the full list of users, modify it,
        # and then use this API to set the final list of users.
        # @param [JSON] body New organization data.
        # @option body [String] owner_email Email address of the organization owner
        # @option body [Array<String>] users List of users who are organization members.
        # @return [200] The organization was changed successfully.
        # @return [404] The organization does not exist
        # @return [404] A user in the list of members does not exist
        # @example Modify the 'example' organization to have user1 & user2 as members
        #   POST /organizations/example <= {"users": ["user1", "user2"]}
        # @example Modify the 'example' organization to change the owner email
        #   POST /organizations/example <= {"owner_email": "bob@example.com"}

        # @!endgroup

        # Sinatra callback
        # @private
        def self.registered(app)
          include Errors::HTTPErrors

          # Get a specific organization.
          app.get do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # Base64 encode the public key
            public_key = Base64.strict_encode64(org.rsa_public_key)

            # Convert to a Hash, sanitize and inject the Users data & encoded
            # RSA key
            org_hash = sanitize_organization(org.serializable_hash)
            org_hash['users'] = org.users.map(&:username)
            org_hash['public_key'] = public_key

            return org_hash.to_json
          end

          # Modify a specific organization.
          app.put do
            authorized_for!(params[:name], Operations::WRITE)

            payload = parse_request_body
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
