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
    # Module for all User related API endpoints
    module Users
      # API endpoints for a single Organization document
      # @api REST
      module Document
        # @!group Users

        # @!method get_users_user
        # @overload GET /users/:username
        # @macro rest
        # @param [String] username Username of the user.
        # Get a specific user.
        # @return The requested user.
        # @return [404] The user does not exist

        # @!method put_users_user(body)
        # @overload PUT /users/:username
        # @macro rest
        # @param [String] username Username of the user.
        # Modify a specific user.
        # @param [JSON] body User information
        # @option body [String] name Users real name
        # @option body [String] email Users new email address
        # @option body [String] password New Bcrypt2 encrypted password
        # @option body [String] new_password New password in plain text, which will be
        #   encrypted before being stored in the databaase.
        # @option body [String] secret New HMAC signing secret. This should be a suitably
        #   long random string.
        # @return [200] User was modified successfully
        # @return [400] The user definition is invalid
        # @return [404] The user does not exist

        # @!method delete_users_user
        # @overload DELETE /users/:username
        # @macro rest
        # @param [String] username Username of the user.
        # Delete a specific user.
        # @return [200] User was deleted successfully
        # @return [404] The user does not exist

        # @!endgroup

        # Sinatra callback
        # @private
        def self.registered(app)
          include Errors::HTTPErrors

          # Get a specific user.
          app.get do
            authorized_as!(params[:username], Operations::READ)

            user = User.find_by(username: params[:username])
            halt_with_json_response(404, INVALID_USER, 'user does not exist') \
              if user.nil?

            Cyclid.logger.debug user.organizations

            # Convert to a Hash and inject the User data
            user_hash = user.serializable_hash
            user_hash['organizations'] = user.organizations.map(&:name)

            user_hash = sanitize_user(user_hash)

            return user_hash.to_json
          end

          # Modify a specific user.
          app.put do
            authorized_as!(params[:username], Operations::WRITE)

            payload = parse_request_body
            Cyclid.logger.debug payload

            user = User.find_by(username: params[:username])
            halt_with_json_response(404, INVALID_USER, 'user does not exist') \
              if user.nil?

            begin
              user.name = payload['name'] if payload.key? 'name'
              user.email = payload['email'] if payload.key? 'email'
              user.password = payload['password'] if payload.key? 'password'
              user.secret = payload['secret'] if payload.key? 'secret'
              user.new_password = payload['new_password'] if payload.key? 'new_password'
              user.save!
            rescue ActiveRecord::ActiveRecordError => ex
              Cyclid.logger.debug ex.message
              halt_with_json_response(400, INVALID_JSON, ex.message)
            end

            return json_response(NO_ERROR, "user #{payload['username']} modified")
          end

          # Delete a specific user.
          app.delete do
            authorized_as!(params[:username], Operations::ADMIN)

            user = User.find_by(username: params[:username])
            halt_with_json_response(404, INVALID_USER, 'user does not exist') \
              if user.nil?

            begin
              user.delete
            rescue ActiveRecord::ActiveRecordError => ex
              Cyclid.logger.debug ex.message
              halt_with_json_response(400, INVALID_JSON, ex.message)
            end

            return json_response(NO_ERROR, "user #{params['username']} deleted")
          end
        end
      end
    end
  end
end
