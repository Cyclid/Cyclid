require 'net/ssh'
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
            rescue Net::SSH::AuthenticationFailed
              Cyclid.logger.debug 'SSH authentication failed'
            end

            sleep 5

            raise 'timed out waiting for SSH' \
              if (Time.now - start) >= 30
          end
        end

        # Execute a command via. SSH
        def exec(cmd, path = nil)
          command = build_command(cmd, path, @env)
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

          @exit_code == 0 && @exit_signal.nil? ? true : false
        end

        # Close the SSH connection
        def close
          logout

          @session.close
        end

        private

        def logout
          exec 'exit'
        end

        def build_command(cmd, path = nil, env = {})
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
          command << cmd
          command.join(';')
        end

        # Register this plugin
        register_plugin 'ssh'
      end
    end
  end
end
