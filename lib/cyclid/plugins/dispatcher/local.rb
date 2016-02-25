# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Local Sidekiq based dispatcher
      class Local < Dispatcher

        def dispatch(job, record)
          Cyclid.logger.debug "dispatching job: #{job}"

          record.job_name = job.name
          record.job_version = job.version
          record.job = job.to_hash.to_json
          record.save!

          # XXX Create a SideKiq worker and pass in the job
          # XXX Testing; just create a Runner
          begin
            runner = Cyclid::API::Job::Runner.new(job.to_hash.to_json, record.id)
            runner.run
          rescue StandardError => ex
            Cyclid.logger.error "job runner failed: #{ex}"
            raise ex
          end

          # The JobRecord ID is as good a job identifier as anything
          return record.id
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
