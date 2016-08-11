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
        def checkout(transport, ctx, source = {})
          source.symbolize_keys!

          raise 'invalid git source definition' \
            unless source.key? :url

          # Add any context data (which could include secrets)
          source = source.interpolate(ctx)

          url = URI(source[:url])

          # If the source includes an OAuth token, add it to the URL as the
          # username
          url.user = source[:token] if source.key? :token

          success = transport.exec "git clone #{url}"
          return false unless success

          # If a branch was given, check it out
          if source.key? :branch
            branch = source[:branch]

            match = url.path.match(%r{^.*\/(\w*)})
            source_dir = "#{ctx[:workspace]}/#{match[1]}"

            success = transport.exec("git fetch origin #{branch}:#{branch}", source_dir)
            success = transport.exec("git checkout #{branch}", source_dir) \
              unless success == false
          end

          return success
        end

        # Register this plugin
        register_plugin 'git'
      end
    end
  end
end
