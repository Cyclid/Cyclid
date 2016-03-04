# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Debian provisioner
      class Debian < Provisioner
        # Prepare a Debian based build host
        def prepare(transport, buildhost, env = {})
          begin
            env[:repos].each do |repo|
              # XXX Repos probably need to be more complex than a simple list;
              # URLs, components & key ID's will be required
              raise 'adding repositories on Debian is not yet supported!'
            end if env.key? :repos

            success = transport.exec 'sudo apt-get update'
            raise "failed to update repositories" unless success

            env[:packages].each do |package|
              success = transport.exec "sudo apt-get install -y #{package}"
              raise "failed to install package #{package}" unless success
            end if env.key? :packages
          rescue StandardError => ex
            Cyclid.logger.error "failed to provision #{buildhost[:name]}: #{ex}"
            raise
          end
        end

        # Register this plugin
        register_plugin 'debian'
      end
    end
  end
end
