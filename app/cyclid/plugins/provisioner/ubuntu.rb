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
      # Ubuntu provisioner
      class Ubuntu < Provisioner
        # Prepare an Ubuntu based build host
        def prepare(transport, buildhost, env = {})
          transport.export_env('DEBIAN_FRONTEND' => 'noninteractive')

          if env.key? :repos
            # Ensure apt-get-repository is available
            transport.exec 'apt-get install -y software-properties-common'

            env[:repos].each do |repo|
              next unless repo.key? :url

              # Check if it's a PPA, or a traditional repository
              url = repo[:url]
              match = url.match(/\A(ppa|http|https):.*\Z/)
              next unless match

              case match[1]
              when 'ppa'
                add_ppa_repository(transport, url)
              when 'http', 'https'
                add_http_repository(transport, url, repo, buildhost)
              end
            end

            success = transport.exec 'apt-get update'
            raise 'failed to update repositories' unless success
          end

          if env.key? :packages
            success = transport.exec \
              "apt-get install -y #{env[:packages].join(' ')}" \

            raise "failed to install packages #{env[:packages].join(' ')}" unless success
          end
        rescue StandardError => ex
          Cyclid.logger.error "failed to provision #{buildhost[:name]}: #{ex}"
          raise
        end

        private

        def add_ppa_repository(transport, url)
          success = transport.exec "apt-add-repository -y #{url}"
          raise "failed to add repository #{url}" unless success
        end

        def add_http_repository(transport, url, repo, buildhost)
          raise 'an HTTP repository must provide a list of components' \
            unless repo.key? :components

          # Create a sources.list.d fragment
          release = buildhost[:release]
          components = repo[:components]
          fragment = "deb #{url} #{release} #{components}"

          success = transport.exec \
            "sh -c \"echo '#{fragment}' | tee -a /etc/apt/sources.list.d/cyclid.list\""
          raise "failed to add repository #{url}" unless success

          return unless repo.key? :key_id

          # Import the signing key
          key_id = repo[:key_id]

          success = transport.exec \
            "gpg --keyserver keyserver.ubuntu.com --recv-keys #{key_id}"
          raise "failed to import key #{key_id}" unless success

          success = transport.exec \
            "sh -c 'gpg -a --export #{key_id} | apt-key add -'"
          raise "failed to add repository key #{key_id}" unless success
        end

        # Register this plugin
        register_plugin 'ubuntu'
      end
    end
  end
end
