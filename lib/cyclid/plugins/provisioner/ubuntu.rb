# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Ubuntu provisioner
      class Ubuntu < Provisioner
        # Prepare an Ubuntu based build host
        def prepare(transport, buildhost, env = {})
          begin
            if env.key? :repos
              env[:repos].each do |repo|
                # XXX Check that it's actually a PPA
                success = transport.exec "sudo apt-add-repository -y #{repo}"
                raise "failed to add repository #{repo}" unless success
              end

              success = transport.exec 'sudo apt-get update'
              raise "failed to update repositories" unless success
            end

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
        register_plugin 'ubuntu'
      end
    end
  end
end
