# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Base class for Dispatcher
      class Dispatcher < Base

        # Dispatch a job to a worker and return some opaque data that can be
        # used to identify that job (E.g. an ID, UUID etc.)
        def dispatch(job)
        end

      end
    end
  end
end 

require_rel 'dispatcher/*.rb'
