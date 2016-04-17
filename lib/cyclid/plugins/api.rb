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

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Container for the Sinatra related controllers modules
      module ApiExtension
        # Sinatra controller; this is more complex than usual to allow the
        # plugin to connect it's own set of methods as callbacks.
        class Controller < Module
          attr_reader :plugin_methods

          def initialize(methods = nil)
            @plugin_methods = methods
          end

          # Sinatra callback
          def registered(app)
            include Errors::HTTPErrors

            app.get do
              Cyclid.logger.debug 'ApiExtension::Controller::get'

              org = Organization.find_by(name: params[:name])
              halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
                if org.nil?

              config = controller_plugin.get_config(org)

              get(http_headers(request.env), config['config'])
            end

            app.post do
              Cyclid.logger.debug 'ApiExtension::Controller::post'

              payload = parse_request_body

              org = Organization.find_by(name: params[:name])
              halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
                if org.nil?

              config = controller_plugin.get_config(org)

              post(payload, http_headers(request.env), config['config'])
            end

            app.put do
              Cyclid.logger.debug 'ApiExtension::Controller::put'

              payload = parse_request_body

              org = Organization.find_by(name: params[:name])
              halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
                if org.nil?

              config = controller_plugin.get_config(org)

              put(payload, http_headers(request.env), config['config'])
            end

            app.delete do
              Cyclid.logger.debug 'ApiExtension::Controller::delete'

              org = Organization.find_by(name: params[:name])
              halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
                if org.nil?

              config = controller_plugin.get_config(org)

              delete(http_headers(request.env), config['config'])
            end

            app.helpers do
              include Helpers
              include Job::Helpers
            end
          end
        end

        # Default method callbacks.
        #
        # The use of a 405 response here is slightly wrong as technically each
        # method *is* implemented. We're supposed to send back an Allow: header
        # to indicate which methods we do support, but that'd be all four of
        # them...
        module Methods
          # GET callback
          def get(_headers, _config)
            authorize('get')
            return_failure(405, 'not implemented')
          end

          # POST callback
          def post(_data, _headers, _config)
            authorize('post')
            return_failure(405, 'not implemented')
          end

          # PUT callback
          def put(_data, _headers, _config)
            authorize('put')
            return_failure(405, 'not implemented')
          end

          # DELETE callback
          def delete(_headers, _config)
            authorize('delete')
            return_failure(405, 'not implemented')
          end
        end

        # Standard helpers for API extensions. Mostly the point is to try to
        # hide as much of the underlying Sinatra implementation as possible and
        # simplify (& therefore control) the plugins ability to interact with
        # Sinatra.
        module Helpers
          # Wrapper around the standard Warden authn/authz
          #
          # ApiExtension methods can choose to be authenticated or
          # unauthenticated; for example a callback hook from an external SCM
          # could accept unauthenticated POST's that trigger some action.
          #
          # The callback method implementations can choose to call authorize()
          # if the endpoint would be authenticated, or not to call it in which
          # case the method would be unauthenticated.
          def authorize(method)
            method.downcase!
            operation = if method == 'get'
                          Operations::READ
                        elsif method == 'put'
                          Operations::WRITE
                        elsif method == 'post' or
                              method == 'delete'
                          Operations::ADMIN
                        else
                          raise "invalid method #{method}"
                        end

            authorized_for!(params[:name], operation)
          end

          # Return a standard Cyclid style failure.
          def return_failure(code, message)
            halt_with_json_response(code, Errors::HTTPErrors::PLUGIN_ERROR, message)
          end

          # Extract headers from the raw request & pretty them up
          def http_headers(environment)
            http_headers = headers
            environment.each do |env|
              key, value = env
              match = key.match(/\AHTTP_(.*)\Z/)
              next unless match

              header = match[1].split('_').map(&:capitalize).join('-')
              http_headers[header] = value
            end

            return http_headers
          end
        end
      end

      # Base class for Api plugins
      class Api < Base
        # Return a new instance of the Sinatra controller
        def self.controller
          return ApiExtension::Controller.new(ApiExtension::Methods)
        end

        # Return the 'human' name for the plugin type
        def self.human_name
          'api'
        end
      end
    end
  end
end

require_rel 'api/*.rb'
