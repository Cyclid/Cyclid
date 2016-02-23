# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Base class for Transport plugins
      class Transport < Base
        def initialize(args={})
        end
      end
    end
  end
end

require_rel 'transport/*.rb'
