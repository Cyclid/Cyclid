# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Job related classes
    module Job
      # Run a job
      class Runner
        def initialize(job, job_id)
          # XXX Get a BuildHost
          # XXX Create a LogBuffer
          # XXX Create a Transport & connect it to the BuildHost
          # XXX Prepare the BuildHost
          # XXX Run the Job stage actions
        end
      end
    end
  end
end
