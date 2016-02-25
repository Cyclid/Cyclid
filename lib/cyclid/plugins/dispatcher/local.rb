# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Local Sidekiq based dispatcher
      class Local < Dispatcher

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
