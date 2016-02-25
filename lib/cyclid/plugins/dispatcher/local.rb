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
            notifier = Notifier::Local.new(record.id)
            runner = Cyclid::API::Job::Runner.new(record.id, job.to_hash.to_json, notifier)
            runner.run
          rescue StandardError => ex
            Cyclid.logger.error "job runner failed: #{ex}"
            raise ex
          end

          # The JobRecord ID is as good a job identifier as anything
          return record.id
        end

        # Register this plugin
        register_plugin 'local'
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
      # This is a local Notifier, so it can just pass updates directly on to
      # the JobRecord & LogBuffer
      module Notifier
        class Local
          def initialize(job_id)
            @job_record = JobRecord.find(job_id)
            # Create a LogBuffer
            @log_buffer = LogBuffer.new(@job_record)
          end

          # Set the JobRecord status
          def status=(status)
            @job_record.status = status
            @job_record.save!
          end

          # Set the JobRecord ended
          def ended=(time)
            @job_record.ended = time
            @job_record.save!
          end

          # Write data to the log buffer
          def write(data)
            @log_buffer.write data
          end
        end
      end

    end
  end
end
