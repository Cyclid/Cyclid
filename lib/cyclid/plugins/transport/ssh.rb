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
        def initialize(args={})
          args.symbolize_keys!

          # Hostname, username & a log target are required
          return false unless args.include? :host and \
                              args.include? :user and \
                              args.include? :log

          password = args[:password] if args.include? :password

          @log = args[:log]

          # Create an SSH channel and connect the callbacks to the log target
          @session = Net::SSH.start(args[:host], args[:user], password: password)
          @channel = @session.open_channel do |channel|
            channel.send_channel_request 'shell' do |ch, success|
              # XXX raise
              abort 'failed to open shell' unless success
            end

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
              Cyclid.logger.debug "exit_code=#{@exit_code}"
            end

            # Capture a command exiting with a signal
            channel.on_request 'exit-signal' do |ch, data|
              @exit_signal = data.read_long
              Cyclid.logger.debug "exit_signal=#{@exit_signal}"
            end
          end
        end

        def export_env(env={})
          env.each do |key, value|
            key.upcase!
            key.gsub!(/\s/, '_')
            exec "export #{key}=\"#{value}\""
          end
        end

        def exec(cmd)
          @channel.send_data("#{cmd}\n")
        end

        def close
          logout

          @channel.wait
          @channel.close
          @session.close
        end

        private

        def logout
          exec 'logout'
        end

        # Register this plugin
        register_plugin 'ssh'
      end

    end
  end
end
