require 'net/ssh'
require 'cyclid/log_buffer'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    class Transport
      def initialize(host, user, log: nil, password: nil)
        @log = log

        @session = Net::SSH.start(host, user, password: password)
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
    end
  end
end
