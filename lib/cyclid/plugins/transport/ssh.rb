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

        def initialize(args={})
          args.symbolize_keys!

          # Hostname, username & a log target are required
          return false unless args.include? :host and \
                              args.include? :user and \
                              args.include? :log

          password = args[:password] if args.include? :password

          @log = args[:log]

          # Create an SSH channel
          @session = Net::SSH.start(args[:host], args[:user], password: password)
        end

        def export_env(env={})
          @env = env
        end

        def exec(cmd, path=nil)
          command = build_command(cmd, path, @env)
          Cyclid.logger.debug "command=#{command}"

          channel = @session.open_channel do |channel|
            channel.on_open_failed do |ch, code, desc|
              # XXX raise
              abort "failed to open channel: #{desc}"
            end

            # STDOUT
            channel.on_data do |ch, data|
              # Send to Log Buffer
              @log.write data
            end

            # STDERR
            channel.on_extended_data do |ch, type, data|
              # Send to Log Buffer
              @log.write data
            end

            # Capture return value from commands
            channel.on_request 'exit-status' do |ch, data|
              @exit_code = data.read_long
            end

            # Capture a command exiting with a signal
            channel.on_request 'exit-signal' do |ch, data|
              @exit_signal = data.read_long
            end

            channel.exec command do |ch, success|
            end
          end

          # Run the SSH even loop; this blocks until the command has completed
          @session.loop

          @exit_code == 0 && @exit_signal.nil? ? true : false
        end

        def close
          logout

          @session.close
        end

        private

        def logout
          exec 'exit'
        end

        def build_command(cmd, path=nil, env={})
          command = []
          if env
            vars = env.map do |k, value|
              key = k.upcase
              key.gsub!(/\s/, '_')
              "export #{key}=\"#{value}\""
            end
            command << vars.join(';')
          end

          if path
            command << "cd #{path}"
          end

          command << cmd
          command.join(';')
        end

        # Register this plugin
        register_plugin 'ssh'
      end

    end
  end
end
