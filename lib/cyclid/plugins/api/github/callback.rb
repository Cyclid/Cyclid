# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Container for the Sinatra related controllers modules
      module ApiExtension
 
        # XXX Move me
        class Callback
          def completion(job_id, status)
          end

          def status_changed(job_id, status)
          end

          def log_write(job_id, data)
          end
        end

        class GithubCallback < Callback
          def initialize(statuses, auth_token)
            @statuses = statuses
            @auth_token = auth_token
          end

          def status_changed(job_id, status)
            case status
            when Constants::JobStatus::WAITING
              state = 'pending'
              message = "Queued job ##{job_id}."
            when Constants::JobStatus::STARTED
              state = 'pending'
              message = "Job ##{job_id} started."
            when Constants::JobStatus::FAILING
              state = 'failure'
              message = "Job ##{job_id} failed. Waiting for job to complete."
            else
              return false
            end

            GithubStatus.set_status(@statuses, @auth_token, state, message)
          end

          def completion(job_id, status)
            if status == true
              state = 'success'
              message = "Job ##{job_id} completed successfuly."
            else
              state = 'failure'
              message = "Job ##{job_id} failed."
            end
            GithubStatus.set_status(@statuses, @auth_token, state, message)
          end
        end
      end
    end
  end
end
