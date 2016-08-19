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
      # API endpoints for Organization members
      # @api REST
      module Members
        # @!group Organizations

        # @!method get_organizations_organization_members_member
        # @overload GET /organizations/:organization/members/:username
        # @macro rest
        # @param [String] organization Name of the organization.
        # @param [String] username Username of the member.
        # Get the details of the specified user within the organization.
        # @return The requested member.
        # @return [404] The organization or user does not exist, or the user is not a member of
        #   the organization.
        # @example Get the 'user1' user from the 'example' organization
        #   GET /organizations/example/members/user1 => {"id": 1,
        #                                                "username": "user1",
        #                                                "email":"test@example.com",
        #                                                "permissions":{
        #                                                  "admin":true,
        #                                                  "write":true,
        #                                                  "read":true
        #                                                 }}

        # @!method put_organizations_organization_members_member
        # @overload PUT /organizations/:name/members/:username
        # @macro rest
        # @param [String] organization Name of the organization.
        # @param [String] username Username of the member.
        # Modify the permissions of specified user within the organization.
        # @param [JSON] body User permissions.
        # @option body [Hash] permissions Permissions to apply for the user.
        # @return [200] The member was modified successfully.
        # @return [404] The user does not exist, or is not a member of the organization.
        # @example Give the member 'user1' write & read permissions for the 'example' organization
        #   PUT /organizations/example/members/user1 <= {"permissions": {
        #                                                  "admin":false,
        #                                                  "write":true,
        #                                                  "read":true
        #                                                 }}

        # @!endgroup

        # Sinatra callback
        # @private
        def self.registered(app)
          include Errors::HTTPErrors

          # Get the details of the specified user within the organization.
          app.get '/:username' do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            user = org.users.find_by(username: params[:username])
            halt_with_json_response(404, INVALID_USER, 'user does not exist') \
              if user.nil?

            begin
              perms = user.userpermissions.find_by(organization: org)

              user_hash = user.serializable_hash
              user_hash.delete_if do |key, _value|
                key == 'password' || key == 'secret'
              end

              perms_hash = perms.serializable_hash
              perms_hash.delete_if do |key, _value|
                key == 'id' || key == 'user_id' || key == 'organization_id'
              end

              user_hash['permissions'] = perms_hash

              return user_hash.to_json
            rescue ActiveRecord::ActiveRecordError, \
                   ActiveRecord::UnknownAttributeError => ex

              Cyclid.logger.debug ex.message
              halt_with_json_response(500, INTERNAL_ERROR, ex.message)
            end
          end

          # Modify the specified user within the organization.
          app.put '/:username' do
            authorized_for!(params[:name], Operations::WRITE)

            payload = parse_request_body
            Cyclid.logger.debug payload

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            user = org.users.find_by(username: params[:username])
            halt_with_json_response(404, INVALID_USER, 'user does not exist') \
              if user.nil?

            begin
              perms = user.userpermissions.find_by(organization: org)

              payload_perms = payload['permissions'] if payload.key? 'permissions'
              unless payload_perms.nil?
                perms.admin = payload_perms['admin'] if payload_perms.key? 'admin'
                perms.write = payload_perms['write'] if payload_perms.key? 'write'
                perms.read = payload_perms['read'] if payload_perms.key? 'read'

                Cyclid.logger.debug perms.serializable_hash

                perms.save!
              end
            rescue ActiveRecord::ActiveRecordError, \
                   ActiveRecord::UnknownAttributeError => ex

              Cyclid.logger.debug ex.message
              halt_with_json_response(500, INTERNAL_ERROR, ex.message)
            end
          end
        end
      end
    end
  end
end
