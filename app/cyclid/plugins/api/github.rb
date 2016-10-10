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

require_rel 'github/methods'
require_rel 'github/status'
require_rel 'github/callback'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # API extension for Github hooks
      class Github < Api
        # Return an instance of the Github API controller
        def self.controller
          routes = [{verb: :get, path: '/oauth/request', func: 'oauth_request'},
                    {verb: :get, path: '/oauth/callback', func: 'oauth_callback'}]

          return ApiExtension::Controller.new(ApiExtension::GithubMethods, routes)
        end

        class << self
          # Merge the given config into the current config & validate
          def update_config(config, new)
            Cyclid.logger.debug "config=#{config} new=#{new}"

            if new.key? 'repository_tokens'
              Cyclid.logger.debug 'updating repository tokens'

              new_tokens = new['repository_tokens']
              current_tokens = config['repository_tokens']

              raise 'repository_tokens must be an array' \
                unless new_tokens.is_a? Array

              # Merge the current list of tokens with the new list of tokens;
              # we have to do this in a 'roundabout fashion:
              #
              # 1. Convert both into a hash, with the url as the key and
              #    the original hash itself as the value. E.g.
              #    {url: 'example.com', token: 'abcdef'} becomes
              #    {'exmaple.com': {url: 'example.com', token: 'abcdef'}}
              # 2. Merge the new hash into the current hash; this will
              #    over-write any existing entries.
              # 3. Obtain the values of the the resulting merged object, which
              #    is an array of the original hashes.
              #
              # Thanks, Stackoverflow!
              new_hash = Hash[new_tokens.map{ |h| [h['url'], h] }]
              current_hash = Hash[current_tokens.map{ |h| [h['url'], h] }]

              merged = current_hash.merge(new_hash).values

              # Delete any entries where the token value is nil
              merged.delete_if do |entry|
                entry['token'].nil?
              end

              config['repository_tokens'] = merged
            end

            if new.key? 'hmac_secret'
              Cyclid.logger.debug 'updating HMAC secret'
              config['hmac_secret'] = new['hmac_secret']
            end

            return config
          end

          # Default configuration
          def default_config
            config = {}
            config['repository_tokens'] = []
            config['hmac_secret'] = nil

            return config
          end

          # Github plugin configuration schema
          def config_schema
            schema = []
            schema << { name: 'repository_tokens',
                        type: 'hash-list',
                        description: 'Repository OAuth tokens',
                        default: [] }
            schema << { name: 'hmac_secret',
                        type: 'string',
                        description: 'Github HMAC signing secret',
                        default: nil }

            return schema
          end
        end

        # Register this plugin
        register_plugin 'github'
      end
    end
  end
end
