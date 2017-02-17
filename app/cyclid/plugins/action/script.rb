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

require 'securerandom'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Script plugin
      class Script < Action
        def initialize(args = {})
          args.symbolize_keys!

          # At a bare minimum there has to be a script to execute.
          raise 'a command action requires a script' unless args.include? :script

          # Scripts can either be a single string, or an array of strings
          # which we will join back together
          @script = if args[:script].is_a? String
                      args[:script]
                    elsif args[:script].is_a? Array
                      args[:script].join("\n")
                    end

          # If no explicit path was given, create a temporary filename.
          # XXX This assumes the remote system has a /tmp, that it's writable
          # and not mounted NOEXEC, but there's no easy way to do this?
          @path = if args.include? :path
                    args[:path]
                  else
                    file = "cyclid_#{SecureRandom.hex(16)}"
                    File.join('/', 'tmp', file)
                  end

          @env = args[:env] if args.include? :env

          Cyclid.logger.debug "script: '#{@script}' path: #{@path}"
        end

        # Run the script action
        def perform(log)
          begin
            # Export the environment data to the build host, if necesary
            env = @env % @ctx if @env
            @transport.export_env(env)

            # Add context data
            script = @script ** @ctx
            path = @path ** @ctx

            # Create an IO object containing the script and upload it to the
            # build host
            log.write("Uploading script to #{path}\n")

            io = StringIO.new(script)
            @transport.upload(io, path)

            # Execute the script
            log.write("Running script from #{path}...\n")
            success = @transport.exec("chmod +x #{path} && #{path}")
          rescue KeyError => ex
            # Interpolation failed
            log.write "#{ex.message}\n"
            success = false
          end

          [success, @transport.exit_code]
        end

        # Register this plugin
        register_plugin 'script'
      end
    end
  end
end
