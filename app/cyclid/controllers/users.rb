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

require_rel 'users/*.rb'

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Controller for all User related API endpoints
    class UserController < ControllerBase
      helpers do
        # Remove sensitive data from the users data
        def sanitize_user(user)
          user.delete_if do |key, _value|
            key == 'password' || key == 'secret'
          end
        end
      end

      register Sinatra::Namespace

      namespace '/users' do
        register Users::Collection

        namespace '/:username' do
          register Users::Document
        end
      end
    end

    # Register this controller
    Cyclid.controllers << UserController
  end
end
