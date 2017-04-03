# frozen_string_literal: true
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

require_rel '../helpers/docker'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Docker based transport
      class DockerApi < Transport
        include Cyclid::API::Plugins::Helpers::Docker

        attr_reader :exit_code

        def initialize(args = {})
          args.symbolize_keys!

          Cyclid.logger.debug "Docker Transport: args=#{args}"

          # Configure Docker
          config = load_docker_config(
            Cyclid.config.plugins
          )
          ::Docker.url = config[:api]

          # Container name & a log target are required
          return false unless args.include?(:host) && \
                              args.include?(:log)

          @container = get_container(args[:host])
          @log = args[:log]

          ctx = args[:ctx]
          @username = ctx[:username]
        end

        # Execute a command via the Docker API
        def exec(cmd, path = nil)
          command = build_command(cmd, path)
          Cyclid.logger.debug "command=#{command}"
          result = @container.exec(command, wait: 300) do |_stream, chunk|
            @log.write chunk
          end
          @exit_code = result[2]
          @exit_code.zero? ? true : false
        end

        # Copy data from local IO object to a remote file
        def upload(io, path)
          @container.store_file(path, io.read)
        end

        # Copy data from remote file to local IO
        def download(io, path)
          result = @container.read_file(path)
          io.write(result)
        end

        register_plugin('dockerapi')

        private

        def build_command(cmd, path = nil)
          command = []
          command << "cd #{path}" if path
          command << if @username == 'root'
                       cmd
                     else
                       "sudo -E #{cmd}"
                     end
          ['sh', '-l', '-c', command.join(';')]
        end
      end
    end
  end
end
