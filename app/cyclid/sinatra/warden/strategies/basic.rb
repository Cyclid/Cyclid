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
require 'bcrypt'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Warden Strategies
    module Strategies
      # HTTTP Basic authentication based strategy
      module Basic
        # Authenticate via. HTTP Basic auth.
        Warden::Strategies.add(:basic) do
          def valid?
            request.env['HTTP_AUTHORIZATION'].is_a? String and \
              request.env['HTTP_AUTHORIZATION'] =~ /^Basic .*$/
          end

          def authenticate!
            begin
              authorization = request.env['HTTP_AUTHORIZATION']
              digest = authorization.match(/^Basic (.*)$/).captures.first

              user_pass = Base64.decode64(digest)
              username, password = user_pass.split(':')
            rescue
              fail! 'invalid digest'
            end

            user = User.find_by(username: username)
            if user.nil?
              fail! 'invalid user'
            elsif BCrypt::Password.new(user.password).is_password? password
              success! user
            else
              fail! 'invalid user'
            end
          end
        end
      end
    end
  end
end
