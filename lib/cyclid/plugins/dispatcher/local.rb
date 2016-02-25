# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Local Sidekiq based dispatcher
      class Local < Dispatcher

        def dispatch(job)
          Cyclid.logger.debug "dispatching job: #{job}"
          # XXX Create a new JobRecord
          # XXX Create a SideKiq worker and pass in the job
          return 0 # JobRecord.id
        end

        def status(job_id)
        end

        def log_read(job_id)
        end

        # Register this plugin
        register_plugin 'local'
      end
    end
  end
end
