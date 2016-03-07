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
        def dispatch(job, record, callback = nil)
        end
      end

      # A Runner may be running locally (within the API application context)
      # or remotely. A job runner needs to send updates about the job status
      # but obviously, a remote runner can't just update the JobRecord
      # directly: they may put a message on a queue, which a job at the API
      # application would consume and update the JobRecord.
      #
      # A Notifier provides an abstract method to update the JobRecord
      # status and can also proxy LogBuffer writes.
      #
      module Notifier
        # Base class for Notifiers
        class Base
          def initialize(job_id, callback_object)
          end

          # Update the JobRecord status
          def status=(status)
          end

          # Update the JobRecord ended field
          def ended=(time)
          end

          # Notify any callbacks that the job has completed
          def completion(success)
          end

          # Proxy data to the log buffer
          def write(data)
          end
        end
      end
    end
  end
end

require_rel 'dispatcher/*.rb'
