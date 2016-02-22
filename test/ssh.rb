#!/usr/bin/env ruby
require 'net/ssh'

abort 'Need to pass hostname, username & password' if ARGV.size < 3

class LogBuffer
  def initialize(websocket)
    @websocket = websocket
  end

  def write(data)
    # XXX Append to log
    # XXX Write to web socket
    puts data
  end
end

class Transport
  def initialize(host, user, password=nil)
    @buffer = LogBuffer.new(nil)

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
        @buffer.write data
      end

      # STDERR
      channel.on_extended_data do |ch, type, data|
        # Send to Log Buffer
        @buffer.write data
      end
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

transport = Transport.new(ARGV[0], ARGV[1], ARGV[2])
transport.exec 'uname -a'
transport.exec 'cd /var/log'
transport.exec 'ls -l'
transport.exec 'export A="derp"'
transport.exec 'echo A=$A'
transport.close
