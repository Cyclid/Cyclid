# frozen_string_literal: true
# Copyright 2017, 2016 Liqwyd Ltd.
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
      # Module for helper methods
      module Helpers
        # Redhatish provisioner helper methods
        module Redhat
          # Insert the --quiet flag if required
          def quiet
            @quiet ? '-q' : ''
          end

          # Install the yum-utils package
          def install_yum_utils(transport)
            transport.exec 'yum install -q -y yum-utils'
          end

          # Import a signing key with RPM
          def import_signing_key(transport, key_url)
            transport.exec("rpm #{quiet} --import #{key_url}") \
          end

          # Install a package group with yum
          def yum_groupinstall(transport, groups)
            grouplist = groups.map{ |g| "\"#{g}\"" }.join(' ')
            transport.exec "yum groupinstall #{quiet} -y #{grouplist}"
          end

          # Install a list of packages with yum
          def yum_install(transport, packages)
            transport.exec "yum install #{quiet} -y #{packages.join(' ')}"
          end

          # Add a repository with yum-config-manager
          def yum_add_repo(transport, url)
            transport.exec("yum-config-manager #{quiet} --add-repo #{url}")
          end

          # Use DNF to configure & install Fedora
          def prepare_fedora_dnf(transport, env)
            Cyclid.logger.debug 'using DNF'

            if env.key? :repos
              # We need the config-manager plugin
              transport.exec("dnf install #{quiet} -y 'dnf-command(config-manager)'")

              env[:repos].each do |repo|
                next unless repo.key? :url

                # If there's a key, install it
                import_signing_key(transport, repo[:key_url]) \
                  if repo.key? :key_url

                if repo[:url] =~ /\.rpm$/
                  # If the URL is an RPM just install it
                  transport.exec("dnf install #{quiet} -y #{repo[:url]}")
                else
                  # Not an RPM? Let's hope it's a repo file
                  transport.exec("dnf config-manager #{quiet} --add-repo #{repo[:url]}")
                end
              end
            end

            if env.key? :groups
              groups = env[:groups].map{ |g| "\"#{g}\"" }.join(' ')
              transport.exec "dnf groups install #{quiet} -y #{groups}"
            end

            transport.exec "dnf install #{quiet} -y #{env[:packages].join(' ')}" \
              if env.key? :packages
          end

          # Use YUM to configure & install Fedora
          def prepare_fedora_yum(transport, env)
            Cyclid.logger.debug 'using YUM'

            if env.key? :repos
              # We'll need yum-utils for yum-config-manager
              install_yum_utils(transport)

              env[:repos].each do |repo|
                next unless repo.key? :url

                # If there's a key, install it
                import_signing_key(transport, repo[:key_url]) \
                  if repo.key? :key_url

                if repo[:url] =~ /\.rpm$/
                  # If the URL is an RPM just install it
                  transport.exec("yum install #{quiet} -y --nogpgcheck #{repo[:url]}")
                else
                  # Not an RPM? Let's hope it's a repo file
                  yum_add_repo(transport, repo[:url])
                end
              end
            end

            yum_groupinstall(transport, env[:groups]) \
              if env.key? :groups

            yum_install(transport, env[:packages]) \
              if env.key? :packages
          end

          # Use YUM to configure & install a Redhat-like (RHEL, CentOS etc.)
          def prepare_redhat(transport, env)
            Cyclid.logger.debug 'using YUM'

            if env.key? :repos
              # We'll need yum-utils for yum-config-manager
              install_yum_utils(transport)

              env[:repos].each do |repo|
                next unless repo.key? :url

                # If there's a key, install it
                import_signing_key(transport, repo[:key_url]) \
                  if repo.key? :key_url

                if repo[:url] =~ /\.rpm$/
                  # If the URL is an RPM just install it
                  transport.exec("yum localinstall #{quiet} -y --nogpgcheck #{repo[:url]}")
                else
                  # Not an RPM? Let's hope it's a repo file
                  yum_add_repo(transport, repo[:url])
                end
              end
            end

            yum_groupinstall(transport, env[:groups]) \
              if env.key? :groups

            yum_install(transport, env[:packages]) \
              if env.key? :packages
          end

          # Use YUM & RPM to configure & install a Redhat-like (RHEL, CentOS etc.)
          def prepare_redhat_5(transport, env)
            if env.key? :repos
              env[:repos].each do |repo|
                next unless repo.key? :url

                # If there's a key, install it
                import_signing_key(transport, repo[:key_url]) \
                  if repo.key? :key_url

                # Assume the URL is an RPM
                transport.exec("rpm -U #{quiet} #{repo[:url]}")
              end
            end

            yum_groupinstall(transport, env[:groups]) \
              if env.key? :groups

            yum_install(transport, env[:packages]) \
              if env.key? :packages
          end
        end
      end
    end
  end
end
