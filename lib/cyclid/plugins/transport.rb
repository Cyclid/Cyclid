# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Base class for Transport plugins
      class Transport < Base
        def initialize(args = {})
        end

        # Return the 'human' name for the plugin type
        def self.human_name
          'transport'
        end

        # If possible, export each of the variables in env as a shell
        # environment variables. The default is simply to remember the
        # environment variables, which will be exported each time when a
        # command is run.
        def export_env(env = {})
          @env = env
        end

        # Run a command on the remote host.
        def exec(_cmd, _path = nil)
          false
        end

        # Disconnect the transport
        def close
        end
      end
    end
  end
end

require_rel 'transport/*.rb'
