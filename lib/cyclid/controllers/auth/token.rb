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

require 'jwt'

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Auth related API endpoints
    module Auth
      # API endpoints for managing API tokens
      # @api REST
      module Token
        # @!group Tokens

        # @!method post_token_username
        # @overload POST /token/:username
        # @param [String] username Username of the user to generate a token for.
        # @macro rest
        # Generate a JSON Web Token for use with the Token authentication scheme.
        # The user must authenticate using one of the other available methods
        # (HTTP Basic or HMAC) to obtain a token.
        # @return A JWT token.
        # @return [404] The user does not exist

        # @!endgroup

        # Sinatra callback
        # @private
        def self.registered(app)
          include Errors::HTTPErrors

          app.post '/:username' do
            authorized_as!(params[:username], Operations::READ)

            payload = parse_request_body
            Cyclid.logger.debug payload

            user = User.find_by(username: params[:username])
            halt_with_json_response(404, INVALID_USER, 'user does not exist') \
              if user.nil?

            # Create a JSON Web Token. Use the provided payload as the intial
            # set of claims but remove some of the standard claims we don't
            # want users to be able to set.
            #
            # Requests MAY set 'exp' and 'nbf' if they wish.
            payload.delete_if{ |k, _v| %w(iss aud jti iat sub).include? k }

            # If 'exp' was not set, set it now. Default is +6 hours.
            payload['exp'] = Time.now.to_i + 21_600_000 unless payload.key? 'exp'
            # Subject is this user
            payload['sub'] = params[:username]

            # Create the token; use the users HMAC key as the signing key
            token = JWT.encode payload, user.secret, 'HS256'

            token_hash = { token: token }
            return token_hash.to_json
          end
        end
      end
    end
  end
end
