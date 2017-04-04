# frozen_string_literal: true
# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Module for helper methods
      module Helpers
        # Module for Docker related bits within Cyclid
        module Docker
          # Load the config for the docker builder
          def load_docker_config(config)
            config.symbolize_keys!

            docker_config = config[:docker] || {}
            Cyclid.logger.debug "docker: config=#{docker_config}"

            docker_config[:api] = 'unix:///var/run/docker.sock' \
              unless docker_config.key? :api
            docker_config[:instance_name] = 'cyclid-build' \
              unless docker_config.key? :instance_name

            docker_config
          end

          # Actually create the container
          def create_container(name, image)
            # Pull a suitable image
            Cyclid.logger.debug "Creating image '#{image}'"
            ::Docker::Image.create('fromImage' => image)

            # Create the container
            # XXX How do we (reliably) know what to run? /sbin/init is a good
            # guess but not bullet proof
            Cyclid.logger.debug "Creating container '#{name}'"
            container = ::Docker::Container.create('Name' => name,
                                                   'Image' => image,
                                                   'Cmd' => ['/sbin/init'])
            container.start

            return container
          end

          # Get information about a container
          def get_container(id)
            ::Docker::Container.get(id)
          end
        end
      end
    end
  end
end
