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

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Container for the Sinatra related controllers modules
      module ApiExtension
        # Github plugin method callbacks
        module GithubMethods
          # OAuth related methods
          module OAuth
            # Begin the OAuth authentication flow
            def oauth_request(_headers, config, _data)
              Cyclid.logger.debug('OAuth request')
              #authorize('get')

              begin
                # Retrieve the plugin configuration
                plugins_config = Cyclid.config.plugins
                github_config = load_github_config(plugins_config)

                org_name = params[:name]
                api_url = github_config[:api_url]
                redirect_uri = "#{api_url}/organizations/#{org_name}/plugins/github/oauth/callback"
                # XXX This isn't very useful as we'd need to know what this was
                # when the callback is called; we need something that's generated
                # computationally, like a secure hash of the organization name.
                state = SecureRandom.hex(32) 

                # Redirect the user to the Github OAuth authorization endpoint
                u = URI.parse('https://github.com/login/oauth/authorize')
                u.query = URI.encode_www_form({client_id: github_config[:client_id],
                                               #state: state,
                                               redirect_uri: redirect_uri})
                redirect u
              rescue StandardError => ex
                Cyclid.logger.debug "OAuth redirect failed: #{ex}"
                return_failure(500, 'OAuth redirect failed')
              end
            end

            # OAuth authentication callback
            def oauth_callback(_headers, _config, _data)
              Cyclid.logger.debug('OAuth callback')

              return_failure(500, 'Github OAuth response does not provide a code') \
                unless params.key? 'code'

              begin
                # Retrieve the plugin configuration
                # XXX Needs to be genericised/cached
                plugins_config = Cyclid.config.plugins
                github_config = load_github_config(plugins_config)

                # Exchange the code for a bearer token
                u = URI.parse('https://github.com/login/oauth/access_token')
                u.query = URI.encode_www_form({client_id: github_config[:client_id],
                                               client_secret: github_config[:client_secret],
                                               #state: state,
                                               code: params['code']})

                request = Net::HTTP::Post.new(u)
                request['Accept'] = 'application/json'
                http = Net::HTTP.new(u.hostname, u.port)
                http.use_ssl = (u.scheme == 'https')
                response = http.request(request)
              rescue StandardError => ex
                Cyclid.logger.debug "failed to request OAuth token: #{ex}"
                return_failure(500, 'could not complete OAuth token exchange')
              end

              return_failure(500, "couldn't get OAuth token") \
                unless response.code == '200'

              # Parse the response and extract the OAuth token
              begin
                token = JSON.parse(response.body, {symbolize_names: true})
                access_token = token[:access_token]
              rescue StandardError => ex
                Cyclid.logger.debug "failed to parse OAuth response: #{ex}"
                return_failure(500, 'failed to parse OAuth response')
              end

              # XXX Encrypt the token
              begin
                org = retrieve_organization(params[:name])
                controller_plugin.set_config({oauth_token: access_token}, org)
              rescue Exception => ex
                Cyclid.logger.debug "failed to set plugin configuration: #{ex}"
              end

              # XXX Redirect?
            end
          end
        end
      end
    end
  end
end 
