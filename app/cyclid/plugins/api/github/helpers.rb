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
          # Github event handler helper methods
          module Helpers
            def pull_request
              @pr ||= @payload['pull_request']
            end

            def pr_clone_url
              pull_request['base']['repo']['html_url']
            end

            def pr_head
              @pr_head ||= pull_request['head']
            end

            def pr_sha
              pr_head['sha']
            end

            def pr_ref
              pr_head['ref']
            end

            def pr_repo
              @pr_repo ||= pr_head['repo']
            end

            def pr_status_url
              url = pr_repo['statuses_url']
              @pr_status_url ||= url.gsub('{sha}', pr_sha)
            end

            def pr_trees_url
              url = pr_repo['trees_url']
              @pr_trees_url ||= url.gsub('{/sha}', "/#{pr_sha}")
            end

            def pr_repo
              @repo ||= Octokit::Repository.from_url(pr_clone_url)
            end

            def push_head_commit
              @head_commit ||= @payload['head_commit']
            end

            def push_ref
              @payload['ref']
            end

            def push_sha
              @push_sha ||= push_head_commit['id']
            end

            def push_clone_url
              @push_clone_url ||= @payload['repository']['html_url']
            end

            def push_repo
              @push_repo ||= Octokit::Repository.from_url(push_clone_url)
            end

            def find_oauth_token(config, clone_url)
              # Get an OAuth token, if one is set for this repo
              Cyclid.logger.debug "attempting to find auth token for #{clone_url}"
              auth_token = nil
              config['repository_tokens'].each do |entry|
                entry_url = URI(entry['url'])
                auth_token = entry['token'] if entry_url.host == clone_url.host && \
                                               entry_url.path == clone_url.path
              end
              # If we didn't find a token specifically for this repository, use
              # the organization OAuth token
              auth_token = config['oauth_token'] if auth_token.nil?

              return auth_token
            end

            def find_job_file(tree)
              # See if a .cyclid.yml or .cyclid.json file exists in the project
              # root
              sha = nil
              type = nil
              tree['tree'].each do |file|
                match = file['path'].match(/\A\.cyclid\.(json|yml)\z/)
                next unless match

                sha = file['sha']
                type = match[1]
                break
              end
              [sha, type]
            end

            def load_job_file(repo, sha, type)
              blob = @client.blob(repo, sha)
              case type
              when 'json'
                Oj.load(Base64.decode64(blob.content))
              when 'yml'
                YAML.load(Base64.decode64(blob.content))
              end
            end
          end
        end
      end
    end
  end
end
