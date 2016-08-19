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

require 'warden'
require 'jwt'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Warden Strategies
    module Strategies
      # API Token based strategy
      module APIToken
        # Authenticate via. an API token
        Warden::Strategies.add(:api_token) do
          def valid?
            request.env['HTTP_AUTHORIZATION'].is_a? String and \
              request.env['HTTP_AUTHORIZATION'] =~ /^Token .*$/
          end

          def authenticate!
            begin
              authorization = request.env['HTTP_AUTHORIZATION']
              username, token = authorization.match(/^Token (.*):(.*)$/).captures
            rescue
              fail! 'invalid API token'
            end

            user = User.find_by(username: username)
            fail! 'invalid user' if user.nil?

            begin
              # Decode the token
              token_data = JWT.decode token, user.secret, true, algorithm: 'HS256'
              claims = token_data.first
              if claims['sub'] == user.username
                success! user
              else
                fail! 'invalid user'
              end
            rescue
              fail! 'invalid API token'
            end
          end
        end
      end
    end
  end
end
