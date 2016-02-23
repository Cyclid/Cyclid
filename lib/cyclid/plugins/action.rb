# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Base class for Action plugins
      class Action < Base
        def initialize(args = {})
        end

        # Provide any additional run-time data, such as the transport &
        # context, that the plugin will require for perform() but didn't get
        # during initialize.
        def prepare(args = {})
          @transport = args[:transport]
          @ctx = args[:ctx]
        end

        # Run the Action.
        def perform(log)
        end
      end
    end
  end
end

require_rel 'action/*.rb'
