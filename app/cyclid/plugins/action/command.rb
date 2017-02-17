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
      # Command plugin
      class Command < Action
        Cyclid.logger.debug 'in the Command plugin'

        def initialize(args = {})
          args.symbolize_keys!

          # At a bare minimum there has to be a command to execute.
          raise 'a command action requires a command' unless args.include? :cmd

          # The command & arguments can either be passed seperately, with the
          # args as an array, or as a single string which we then split into
          # a command & array of args.
          if args.include? :args
            @cmd = args[:cmd]
            @args = args[:args]
          else
            cmd_args = args[:cmd].split
            @cmd = cmd_args.shift
            @args = cmd_args
          end

          Cyclid.logger.debug "cmd: '#{@cmd}' args: #{@args}"

          @env = args[:env] if args.include? :env
          @path = args[:path] if args.include? :path
        end

        # Note that we don't need to explicitly use the log for transport
        # related tasks as the transport will take of writing any data from the
        # commands into the log. The log is still passed in to perform() so that
        # plugins can write their own data to it, as we do here by writing out
        # the (optional) path & command that is being run.
        def perform(log)
          begin
            # Export the environment data to the build host, if necesary
            env = @env % @ctx if @env
            @transport.export_env(env)

            # Log the command being run (and the working directory, if one is
            # set)
            cmd_args = "#{@cmd} #{@args.join(' ')}"
            log.write(@path.nil? ? "$ #{cmd_args}\n" : "$ #{@path} : #{cmd_args}\n")

            # Interpolate any data from the job context
            cmd_args = cmd_args ** @ctx

            # Interpolate the path if one is set
            path = @path
            path = path ** @ctx unless path.nil?

            # Run the command
            success = @transport.exec(cmd_args, path)
          rescue KeyError => ex
            # Interpolation failed
            log.write "#{ex.message}\n"
            success = false
          end

          [success, @transport.exit_code]
        end

        # Register this plugin
        register_plugin 'command'
      end
    end
  end
end
