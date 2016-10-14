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
        # Github plugin method callbacks
        module GithubMethods
          # Handle a Pull Request event
          module PullRequest
            # Handle a Github Pull Request event
            def event_pull_request(config)
              # Safely load the JSON event data
              @payload = parse_request_body
              Cyclid.logger.debug "hook payload=#{@payload.inspect}"

              # Do we know what to do with this action?
              action = @payload['action'] || nil

              Cyclid.logger.debug "action=#{action}"
              return true unless action == 'opened' \
                              or action == 'reopened' \
                              or action == 'synchronize'

              # Get the list of files in the root of the repository in the
              # Pull Request branch
              clone_url = URI(pr_clone_url)

              # Get the authentication key
              auth_token = find_oauth_token(config, clone_url)

              return_failure(400, "can not find a valid OAuth token for #{clone_url}") \
                if auth_token.nil?

              # Create an Octokit client
              @client = Octokit::Client.new(access_token: auth_token)

              # Set the PR to 'pending'
              @client.create_status(pr_repo, pr_sha, 'pending', {context: 'Cyclid',
                                                                 description: 'Preparing build'})

              # Get the Pull Request
              tree = @client.tree(pr_repo, pr_sha, recursive: false)
              Cyclid.logger.debug "tree=#{tree.to_hash}"

              # Find the Cyclid job file (if it exists)
              job_sha, job_type = find_job_file(tree)
              Cyclid.logger.debug "job_sha=#{job_sha}"

              if job_sha.nil?
                @client.create_status(pr_repo, pr_sha, 'error', {context: 'Cyclid',
                                                                 description: 'No Cyclid job file found'})
                return_failure(400, 'not a Cyclid repository')
              end

              # Get the job file
              begin
                job_definition = load_job_file(pr_repo, job_sha, job_type)

                # Insert this repository & branch into the sources
                #
                # XXX Could this cause collisions between the existing sources in
                # the job definition? Not entirely sure what the workflow will
                # look like.
                job_sources = job_definition['sources'] || []
                job_sources << { 'type' => 'git',
                                 'url' => clone_url.to_s,
                                 'branch' => pr_ref,
                                 'token' => auth_token }
                job_definition['sources'] = job_sources

                Cyclid.logger.debug "sources=#{job_definition['sources']}"
              rescue StandardError => ex
                Cyclid.logger.error "failed to retrieve Github Pull Request job: #{ex}"

                @client.create_status(pr_repo, pr_sha, 'error', {context: 'Cyclid',
                                                                 description: "Couldn't retrieve Cyclid job file"})
                return_failure(400, 'not a Cyclid repository')
              end

              Cyclid.logger.debug "job_definition=#{job_definition}"

              begin
                # Retrieve the plugin configuration
                plugins_config = Cyclid.config.plugins
                github_config = load_github_config(plugins_config)

                ui_url = github_config[:ui_url]
                linkback_url = "#{ui_url}/#{organization_name}"

                callback = GithubCallback.new(auth_token, pr_repo, pr_sha, linkback_url)
                job_from_definition(job_definition, callback)
              rescue StandardError => ex
                @client.create_status(pr_repo, pr_sha, 'error', {context: 'Cyclid',
                                                                 description: 'An unknown error occurred'})

                return_failure(500, 'job failed')
              end

              return true
            end
          end
        end
      end
    end
  end
end
