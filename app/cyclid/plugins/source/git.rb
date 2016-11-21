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
      # Git source plugin
      class Git < Source
        # Run commands via. the transport to check out a given Git remote
        # repository
        def checkout(transport, ctx, sources = [])
          normalized_sources = normalize_and_dedup(sources)
          normalized_sources.each do |source|
            source.symbolize_keys!

            raise 'invalid git source definition' \
              unless source.key? :url

            # Add any context data (which could include secrets)
            source = source.interpolate(ctx)

            url = URI(source[:url])

            # If the source includes an OAuth token, add it to the URL as the
            # username
            url.user = source[:token] if source.key? :token

            success = transport.exec("git clone #{url}", ctx[:workspace])
            return false unless success

            # If a branch was given, check it out
            next unless source.key? :branch

            branch = source[:branch]

            match = url.path.match(%r{^.*\/([^\.]*)})
            source_dir = "#{ctx[:workspace]}/#{match[1]}"

            success = transport.exec("git fetch origin #{branch}:#{branch}", source_dir)
            return false unless success

            success = transport.exec("git checkout #{branch}", source_dir)
            return false unless success
          end

          return true
        end

        # Register this plugin
        register_plugin 'git'

        private

        # Remove any duplicate source definitions:
        #
        # 1. Normalize the source URLs
        # 2. Find all of the definitions for a given URL and merge them
        def normalize_and_dedup(sources)
          normalized_sources = normalize(sources)
          Cyclid.logger.debug "normalized_sources=#{normalized_sources}"
          deduped_sources = dedup(normalized_sources)
          Cyclid.logger.debug("deduped_sources=#{deduped_sources}")

          return deduped_sources
        end

        # Standardise the Git URLs. Git urls can be of the form:
        #
        # git://github.com/user/project.git#commit-ish
        # git+ssh://user@hostname:project.git#commit-ish
        # git+ssh://user@hostname/project.git#commit-ish
        # git+http://user@hostname/project/blah.git#commit-ish
        # git+https://user@hostname/project/blah.git#commit-ish
        #
        # 1. We won't support SSH; HTTP(s) only
        # 2. Extract the user and treat it as the token parameter
        # 3. Extract the fragment and treat it as the branch parameter
        #
        # So:
        #
        # http[s]://[user@]hostname/project/blah.git[#commit-ish]
        #
        def normalize(sources)
          normalized = sources.map do |source|
            uri = URI.parse(source[:url])
            next unless uri.scheme =~ /\Ahttps?\z/

            s = {}
            s[:url] = "#{uri.scheme}://#{uri.host}#{uri.path.gsub(/.git$/, '')}"
            s[:token] = uri.user if uri.user
            s[:branch] = uri.fragment if uri.fragment
            source.merge(s)
          end
          normalized.compact
        end

        # Merge any duplicate source definitions
        def dedup(sources)
          merged = sources.map do |source|
            all = sources.select { |el| el[:url] == source[:url] }
            all.inject(&:merge)
          end
          merged.uniq
        end
      end
    end
  end
end
