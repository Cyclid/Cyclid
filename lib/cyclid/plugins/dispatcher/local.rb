# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Local Sidekiq based dispatcher
      class Local < Dispatcher
        # Queue the job to be run asynchronously.
        def dispatch(job, record, callback = nil)
          Cyclid.logger.debug "dispatching job: #{job}"

          job_definition = job.to_hash.to_json

          record.job_name = job.name
          record.job_version = job.version
          record.job = job_definition
          record.save!

          # The callback instance has to be serailised into JSON to survive the
          # trip through Redis to Sidekiq
          callback_json = callback.nil? ? nil : Oj.dump(callback)

          # Create a SideKiq worker and pass in the job
          Worker::Local.perform_async(job_definition, record.id, callback_json)

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
        class Local < Base
          def initialize(job_id, callback_object)
            @job_id = job_id
            @job_record = JobRecord.find(job_id)

            # Create a LogBuffer
            @log_buffer = LogBuffer.new(@job_record)

            # Unserialize the callback object, if there is one
            @callback = callback_object.nil? ? nil : Oj.load(callback_object)
          end

          # Set the JobRecord status
          def status=(status)
            @job_record.status = status
            @job_record.save!

            # Ping the callback status_changed hook, if required
            @callback.status_changed(@job_id, status) if @callback
          end

          # Set the JobRecord ended
          def ended=(time)
            @job_record.ended = time
            @job_record.save!
          end

          # Ping the callback completion hook, if required
          def completion(success)
            @callback.completion(@job_id, success) if @callback
          end

          # Write data to the log buffer
          def write(data)
            @log_buffer.write data

            # Ping the callback log_write hook, if required
            @callback.log_write(@job_id, data) if @callback
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
          def perform(job, job_id, callback_object)
            begin
              notifier = Notifier::Local.new(job_id, callback_object)
            rescue StandardError => ex
              Cyclid.logger.debug "couldn't create notifier: #{ex}"
              return false
            end

            begin
              runner = Cyclid::API::Job::Runner.new(job_id, job, notifier)
              success = runner.run
            rescue StandardError => ex
              Cyclid.logger.error "job runner failed: #{ex}"
              success = false
            end

            # Notify completion
            notifier.completion(success)

            return success
          end
        end
      end
    end
  end
end
