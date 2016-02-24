# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Sidekiq based dispatcher
      class Sidekiq < Dispatcher

        def dispatch(job)
        end

        def status(job_id)
        end

        def log_read(job_id)
        end
      end
    end
  end
end
