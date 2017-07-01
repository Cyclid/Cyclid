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

require 'net/ssh'
require 'net/scp'
require 'cyclid/log_buffer'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # SSH based transport
      class Ssh < Transport
        attr_reader :exit_code, :exit_signal

        def initialize(args = {})
          args.symbolize_keys!

          # Hostname, username & a log target are required
          return false unless args.include? :host and \
                              args.include? :user and \
                              args.include? :log

          password = args[:password] if args.include? :password
          keys = [args[:key]] if args.include? :key

          @log = args[:log]

          # Create an SSH channel
          Cyclid.logger.debug 'waiting for SSH...'

          start = Time.now
          loop do
            begin
              @session = Net::SSH.start(args[:host],
                                        args[:user],
                                        password: password,
                                        keys: keys,
                                        timeout: 5)
              break unless @session.nil?
            rescue Net::SSH::Exception
              Cyclid.logger.debug 'SSH authentication failed'
            rescue StandardError => ex
              Cyclid.logger.debug "SSH connection failed: #{ex}"
            end

            sleep 5

            raise 'timed out waiting for SSH' \
              if (Time.now - start) >= 30
          end
        end

        # Execute a command via. SSH
        def exec(cmd, args = {})
          sudo = args[:sudo] || false
          path = args[:path]

          command = build_command(cmd, sudo, path, @env)
          Cyclid.logger.debug "command=#{command}"

          @session.open_channel do |channel|
            channel.on_open_failed do |_ch, _code, desc|
              # XXX raise
              abort "failed to open channel: #{desc}"
            end

            # STDOUT
            channel.on_data do |_ch, data|
              # Send to Log Buffer
              @log.write data
            end

            # STDERR
            channel.on_extended_data do |_ch, _type, data|
              # Send to Log Buffer
              @log.write data
            end

            # Capture return value from commands
            channel.on_request 'exit-status' do |_ch, data|
              @exit_code = data.read_long
            end

            # Capture a command exiting with a signal
            channel.on_request 'exit-signal' do |_ch, data|
              @exit_signal = data.read_long
            end

            channel.exec command do |_ch, _success|
            end
          end

          # Run the SSH even loop; this blocks until the command has completed
          @session.loop

          @exit_code.zero? && @exit_signal.nil? ? true : false
        end

        # Copy data from a local IO object to a remote file via. SCP
        def upload(io, path)
          channel = @session.scp.upload io, path
          channel.wait
        end

        # Copy a data from remote file to a local IO object
        def download(io, path)
          channel = @session.scp.download path, io
          channel.wait
        end

        # Close the SSH connection
        def close
          @session.close
        end

        # Plugin metadata
        def self.metadata
          super.merge!(version: Cyclid::Api::VERSION,
                       license: 'Apache-2.0',
                       author: 'Liqwyd Ltd.',
                       homepage: 'http://docs.cyclid.io')
        end

        private

        def build_command(cmd, sudo, path = nil, env = {})
          command = []
          if env
            vars = env.map do |k, value|
              key = k.upcase
              key.gsub!(/\s/, '_')
              "export #{key}=\"#{value}\""
            end
            command << vars.join(';')
          end

          command << "cd #{path}" if path
          command << if @username == 'root'
                       cmd
                     elsif sudo
                       "sudo -E -n $SHELL -l -c '#{cmd}'"
                     else
                       cmd
                     end
          command.join(';')
        end

        # Register this plugin
        register_plugin 'ssh'
      end
    end
  end
end
