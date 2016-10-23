# frozen_string_literal: true
# Copyright 2016 Liqwyd Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'sidekiq'

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

        # Healthcheck; ensure that Sinatra is available and not under duress
        require 'sidekiq/api'
        extend Health::Helpers

        # Perform a health check; for this plugin that means:
        #
        # Is Sidekiq running?
        # Is the queue size healthy?
        def self.status
          stats = Sidekiq::Stats.new
          if stats.processes_size.zero?
            health_status(:error,
                          'no Sidekiq process is running')
          elsif stats.enqueued > 10
            health_status(:warning,
                          "Sidekiq queue length is too high: #{stats.enqueued}")
          elsif stats.default_queue_latency > 60
            health_status(:warning,
                          "Sidekiq queue latency is too high: #{stats.default_queue_latency}")
          else
            health_status(:ok,
                          'sidekiq is okay')
          end
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
          def initialize(job_id, callback)
            @job_id = job_id
            @job_record = JobRecord.find(job_id)

            # Create a LogBuffer
            @log_buffer = LogBuffer.new(@job_record)

            @callback = callback
          end

          # Set the JobRecord status
          def status=(status)
            @job_record.status = status
            @job_record.save!

            # Ping the callback status_changed hook, if required
            @callback&.status_changed(@job_id, status)
          end

          # Set the JobRecord ended
          def ended=(time)
            @job_record.ended = time
            @job_record.save!
          end

          # Ping the callback completion hook, if required
          def completion(success)
            @callback&.completion(@job_id, success)
          end

          # Write data to the log buffer
          def write(data)
            @log_buffer.write data

            # Ping the callback log_write hook, if required
            @callback&.log_write(@job_id, data)
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
              # Unserialize the callback object, if there is one
              callback = callback_object.nil? ? nil : Oj.load(callback_object)

              notifier = Notifier::Local.new(job_id, callback)
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
