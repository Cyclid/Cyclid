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

            def pr_number
              @pr_number ||= pull_request['number']
            end

            def pr_head
              @pr_head ||= pull_request['head']
            end

            def pr_base
              @pr_base ||= pull_request['base']
            end

            def pr_sha
              pr_head['sha']
            end

            def pr_ref
              pr_head['ref']
            end

            def pr_base_repo
              @pr_base_repo ||= pr_base['repo']
            end

            def pr_base_url
              pr_base_repo['html_url']
            end

            def pr_head_repo
              @pr_head_repo ||= pr_head['repo']
            end

            def pr_head_url
              pr_head_repo['html_url']
            end

            def pr_trees_url
              url = pr_head_repo['trees_url']
              @pr_trees_url ||= url.gsub('{/sha}', "/#{pr_sha}")
            end

            def pr_repository
              @repo ||= Octokit::Repository.from_url(pr_base_url)
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

            def push_repository
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
                match = file['path'].match(/\A\.cyclid\.(json|yml|yaml)\z/)
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
              when 'yaml'
                YAML.load(Base64.decode64(blob.content))
              end
            end

            # Generate a "state" key that can be passed to the OAuth endpoints
            def oauth_state
              org = retrieve_organization
              state = "#{org.name}:#{org.salt}:#{org.owner_email}"
              Base64.urlsafe_encode64(Digest::SHA256.digest(state))
            end

            # Normalize a Github URL into a Cyclid style source definition
            def normalize(url)
              uri = URI.parse(url)

              source = {}
              source['url'] = "#{uri.scheme}://#{uri.host}#{uri.path.gsub(/.git$/, '')}"
              source['token'] = uri.user if uri.user
              source['branch'] = uri.fragment if uri.fragment

              source
            end

            # Extract the "humanish" part from a Git repository URL
            def humanish(uri)
              uri.path.split('/').last.gsub('.git', '')
            end
          end
        end
      end
    end
  end
end
