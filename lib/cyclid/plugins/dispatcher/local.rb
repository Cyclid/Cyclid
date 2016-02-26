# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Local Sidekiq based dispatcher
      class Local < Dispatcher
        # Queue the job to be run asynchronously.
        def dispatch(job, record)
          Cyclid.logger.debug "dispatching job: #{job}"

          job_definition = job.to_hash.to_json

          record.job_name = job.name
          record.job_version = job.version
          record.job = job_definition
          record.save!

          # Create a SideKiq worker and pass in the job
          Worker::Local.perform_async(job_definition, record.id)

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
      module Notifier
        # This is a local Notifier, so it can just pass updates directly on to
        # the JobRecord & LogBuffer
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

      # Namespace for any asyncronous workers
      module Worker
        # Local Sidekiq based worker
        class Local
          include Sidekiq::Worker

          sidekiq_options retry: false

          # Run a job Runner asynchronously
          def perform(job, job_id)
            notifier = Notifier::Local.new(job_id)
            runner = Cyclid::API::Job::Runner.new(job_id, job, notifier)
            runner.run
          rescue StandardError => ex
            Cyclid.logger.error "job runner failed: #{ex}"
            raise ex
          end
        end
      end
    end
  end
end
