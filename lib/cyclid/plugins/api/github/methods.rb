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
          include Methods

          # Return a reference to the plugin that is associated with this
          # controller; used by the lower level code.
          def controller_plugin
            Cyclid.plugins.find('github', Cyclid::API::Plugins::Api)
          end

          # HTTP POST callback
          def post(data, headers, config)
            return_failure(400, 'no event specified') \
              unless headers.include? 'X-Github-Event'

            return_failure(400, 'no delivery ID specified') \
              unless headers.include? 'X-Github-Delivery'

            event = headers['X-Github-Event']
            # Not used yet but will be when we add HMAC support
            # signature = headers['X-Hub-Signature'] || nil

            Cyclid.logger.debug "Github: event is #{event}"

            case event
            when 'pull_request'
              result = gh_pull_request(data, config)
            when 'ping'
              result = true
            when 'status'
              result = true
            else
              return_failure(400, "event type '#{event}' is not supported")
            end

            return result
          end

          # Handle a Github Pull Request event
          def gh_pull_request(data, config)
            action = data['action'] || nil
            pr = data['pull_request'] || nil

            Cyclid.logger.debug "action=#{action}"
            return true unless action == 'opened' \
                            or action == 'reopened' \
                            or action == 'synchronize'

            # Get the list of files in the root of the repository in the
            # Pull Request branch
            html_url = URI(pr['base']['repo']['html_url'])
            pr_sha = pr['head']['sha']
            ref = pr['head']['ref']

            Cyclid.logger.debug "sha=#{pr_sha} ref=#{ref}"

            # Get some useful endpoints & interpolate the SHA for this PR
            url = pr['head']['repo']['statuses_url']
            statuses = url.gsub('{sha}', pr_sha)

            url = pr['head']['repo']['trees_url']
            trees = url.gsub('{/sha}', "/#{pr_sha}")

            # Get an OAuth token, if one is set for this repo
            Cyclid.logger.debug "attempting to find auth token for #{html_url}"
            auth_token = nil
            config['repository_tokens'].each do |entry|
              entry_url = URI(entry['url'])
              auth_token = entry['token'] if entry_url.host == html_url.host && \
                                             entry_url.path == html_url.path
            end

            # XXX We probably don't want to be logging auth tokens in plain text
            Cyclid.logger.debug "auth token=#{auth_token}"

            # Set the PR to 'pending'
            GithubStatus.set_status(statuses, auth_token, 'pending', 'Preparing build')

            # Get the Pull Request
            begin
              trees_url = URI(trees)
              Cyclid.logger.debug "Getting root for #{trees_url}"

              request = Net::HTTP::Get.new(trees_url)
              request.add_field('Authorization', "token #{auth_token}") \
                unless auth_token.nil?

              http = Net::HTTP.new(trees_url.hostname, trees_url.port)
              http.use_ssl = (trees_url.scheme == 'https')
              response = http.request(request)

              Cyclid.logger.debug response.inspect
              raise "couldn't get repository root" \
                unless response.code == '200'

              root = Oj.load response.body
            rescue StandardError => ex
              Cyclid.logger.error "failed to retrieve Pull Request root: #{ex}"
              return_failure(500, 'could not retrieve Pull Request root')
            end

            # See if a .cyclid.yml or .cyclid.json file exists in the project
            # root
            job_url = nil
            job_type = nil
            root['tree'].each do |file|
              match = file['path'].match(/\A\.cyclid\.(json|yml)\z/)
              next unless match

              job_url = URI(file['url'])
              job_type = match[1]
            end

            Cyclid.logger.debug "job_url=#{job_url}"

            if job_url.nil?
              GithubStatus.set_status(statuses, auth_token, 'error', 'No Cyclid job file found')
              return_failure(400, 'not a Cyclid repository')
            end

            # Pull down the job file
            begin
              Cyclid.logger.info "Retrieving PR job from #{job_url}"

              request = Net::HTTP::Get.new(job_url)
              request.add_field('Authorization', "token #{auth_token}") \
                unless auth_token.nil?

              http = Net::HTTP.new(job_url.hostname, job_url.port)
              http.use_ssl = (job_url.scheme == 'https')
              response = http.request(request)
              raise "couldn't get Cyclid job" unless response.code == '200'

              job_blob = Oj.load response.body
              case job_type
              when 'json'
                job_definition = Oj.load(Base64.decode64(job_blob['content']))
              when 'yml'
                job_definition = YAML.load(Base64.decode64(job_blob['content']))
              end

              # Insert this repository & branch into the sources
              #
              # XXX Could this cause collisions between the existing sources in
              # the job definition? Not entirely sure what the workflow will
              # look like.
              job_sources = job_definition['sources'] || []
              job_sources << { 'type' => 'git',
                               'url' => html_url.to_s,
                               'branch' => ref,
                               'token' => auth_token }
              job_definition['sources'] = job_sources

              Cyclid.logger.debug "sources=#{job_definition['sources']}"
            rescue StandardError => ex
              GithubStatus.set_status(statuses,
                                      auth_token,
                                      'error',
                                      "Couldn't retrieve Cyclid job file")
              Cyclid.logger.error "failed to retrieve Github Pull Request job: #{ex}"
              raise
            end

            Cyclid.logger.debug "job_definition=#{job_definition}"

            begin
              callback = GithubCallback.new(statuses, auth_token)
              job_from_definition(job_definition, callback)
            rescue StandardError => ex
              GithubStatus.set_status(statuses, auth_token, 'failure', ex)
              return_failure(500, 'job failed')
            end
          end
        end
      end
    end
  end
end
