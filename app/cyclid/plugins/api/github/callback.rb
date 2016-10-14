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

require 'octokit'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Container for the Sinatra related controllers modules
      module ApiExtension
        # Notifier callback for Github. Updates the external Github Pull
        # Request status as the job progresses.
        class GithubCallback < Plugins::Notifier::Callback
          def initialize(auth_token, repo, sha, linkback_url)
            @auth_token = auth_token
            @repo = repo
            @sha = sha
            @linkback_url = linkback_url
          end

          # Return or create an Octokit client
          def client
            @client ||= Octokit::Client.new(access_token: @auth_token)
          end

          # Job status has changed
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

            target_url = "#{@linkback_url}/job/#{job_id}"
            client.create_status(@repo, @sha, state, {context: 'Cyclid',
                                                      target_url: target_url,
                                                      description: message})
          end

          # Job has completed
          def completion(job_id, status)
            if status == true
              state = 'success'
              message = "Job ##{job_id} completed successfuly."
            else
              state = 'failure'
              message = "Job ##{job_id} failed."
            end
            target_url = "#{@linkback_url}/job/#{job_id}"
            client.create_status(@repo, @sha, state, {context: 'Cyclid',
                                                      target_url: target_url,
                                                      description: message})
          end
        end
      end
    end
  end
end
