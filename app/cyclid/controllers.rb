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

require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/cross_origin'
require 'warden'

require_relative 'sinatra/warden/strategies/basic'
require_relative 'sinatra/warden/strategies/hmac'
require_relative 'sinatra/warden/strategies/api_token'

require_relative 'sinatra/api_helpers'
require_relative 'sinatra/auth_helpers'

# Define some YARD macros that can be used to create the REST API documentation

# @!macro [new] rest
#   @!scope instance
#   @api REST

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Base class for all API Controllers
    class ControllerBase < Sinatra::Base
      include Errors::HTTPErrors

      register Operations
      register Sinatra::Namespace
      register Sinatra::CrossOrigin

      helpers APIHelpers, AuthHelpers

      # The API always returns JSON
      before do
        content_type :json
      end

      # Configure CORS
      configure do
        enable :cross_origin
        set :allow_origin, :any
        set :allow_methods, [:get, :put, :post, :options]
        set :allow_credentials, true
        set :max_age, '1728000'
        set :expose_headers, ['Content-Type']
        disable :show_exceptions
      end

      options '*' do
        response.headers['Allow'] = 'HEAD,GET,PUT,POST,DELETE,OPTIONS'
        response.headers['Access-Control-Allow-Headers'] =
          'Content-Type, Cache-Control, Accept, Authorization'
        200
      end

      # Configure Warden to authenticate
      use Warden::Manager do |config|
        config.serialize_into_session(&:id)
        config.serialize_from_session{ |id| User.find_by_id(id) }

        config.scope_defaults :default,
                              strategies: [:basic, :hmac, :api_token],
                              action: '/unauthenticated'

        config.failure_app = self
      end

      Warden::Manager.before_failure do |env, _opts|
        env['REQUEST_METHOD'] = 'POST'
      end

      register Strategies::Basic
      register Strategies::HMAC
      register Strategies::APIToken

      post '/unauthenticated' do
        content_type :json
        # Stop Warden from calling this endpoint again in an endless loop when
        # it sees the 401 response
        env['warden'].custom_failure!
        halt_with_json_response(401, AUTH_FAILURE, 'invalid username or password')
      end
    end
  end
end

# Load any and all controllers
require_rel 'controllers/*.rb'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Sintra application for the REST API
    class App < Sinatra::Base
      # Set up the Sinatra configuration
      configure do
        enable :logging
      end

      # Register all of the controllers with Sinatra
      Cyclid.controllers.each do |controller|
        Cyclid.logger.debug "Using Sinatra controller #{controller}"
        use controller
      end
    end
  end
end
