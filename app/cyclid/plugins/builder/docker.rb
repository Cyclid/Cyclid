# frozen_string_literal: true
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

require 'docker'
require_rel '../helpers/docker'

# Top level module for the core Cyclid code
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid plugins
    module Plugins
      # Docker build host
      class DockerHost < BuildHost
        # Docker is the only acceptable transport
        def transports
          ['dockerapi']
        end
      end

      # Docker builder, uses the Docker API to create a build host container
      class Docker < Builder
        include Cyclid::API::Plugins::Helpers::Docker

        def initialize
          @config = load_docker_config(
            Cyclid.config.plugins
          )
          ::Docker.url = @config[:api]
        end

        # Create and return a build host
        def get(args = {})
          args.symbolize_keys!

          Cyclid.logger.debug "docker: args=#{args}"

          # If there is one, split the 'os' into a 'distro' and 'release'
          if args.key? :os
            match = args[:os].match(/\A(\w*)_(.*)\Z/)
            distro = match[1] if match
            release = match[2] if match
          else
            # No OS was specified; use the default
            # XXX Defaults should be configurable
            distro = 'ubuntu'
            release = 'trusty'
          end

          # Find the image for the given distribution & release
          image_alias = "#{distro}:#{release}"
          Cyclid.logger.debug "image_alias=#{image_alias}"

          # Create a new instance
          name = create_name
          container = create_container(name, image_alias)

          Cyclid.logger.debug "container=#{container}"

          # Create a buildhost from the container details
          DockerHost.new(
            host: container.id,
            name: name,
            username: 'root',
            workspace: '/root',
            distro: distro,
            release: release
          )
        end

        # Destroy the container when done
        def release(_transport, buildhost)
          container = get_container(buildhost[:host])
          container.delete(force: true)
        end

        # Plugin metadata
        def self.metadata
          super.merge!(version: Cyclid::Api::VERSION,
                       license: 'Apache-2.0',
                       author: 'Liqwyd Ltd.',
                       homepage: 'http://docs.cyclid.io')
        end

        # Register this plugin
        register_plugin 'docker'

        private

        # Get a unique name for the container
        def create_name
          base = @config[:instance_name]
          "#{base}-#{SecureRandom.hex(16)}"
        end
      end
    end
  end
end
