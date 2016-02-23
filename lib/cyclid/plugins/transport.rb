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

        def export_env(env = {})
          @env = env
        end

        def exec(cmd, path = nil)
          false
        end

        def close
        end
      end
    end
  end
end

require_rel 'transport/*.rb'
