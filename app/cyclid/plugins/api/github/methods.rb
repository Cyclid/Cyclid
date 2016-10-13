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

require_relative 'config'
require_relative 'oauth'
require_relative 'pull_request'

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
          include Methods

          include Config
          include OAuth
          include PullRequest

          # Return a reference to the plugin that is associated with this
          # controller; used by the lower level code.
          def controller_plugin
            Cyclid.plugins.find('github', Cyclid::API::Plugins::Api)
          end

          # HTTP POST callback
          def post(headers, config, data)

            return_failure(400, 'no event specified') \
              unless headers.include? 'X-Github-Event'

            return_failure(400, 'no delivery ID specified') \
              unless headers.include? 'X-Github-Delivery'

            event = headers['X-Github-Event']
            # Not used yet but will be when we add HMAC support
            # signature = headers['X-Hub-Signature'] || nil

            Cyclid.logger.debug "Github: event is #{event}"

            case event
            when 'pull_request'
              result = gh_pull_request(data, config)
            when 'ping'
              result = true
            when 'status'
              result = true
            else
              return_failure(400, "event type '#{event}' is not supported")
            end

            return result
          end
        end
      end
    end
  end
end
