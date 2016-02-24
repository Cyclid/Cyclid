#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'require_all'
require 'logger'
require 'active_record'
require 'oj'

require 'cyclid/plugin_registry'

module Cyclid
  class << self
    attr_accessor :logger, :plugins

    Cyclid.plugins = API::Plugins::Registry.new

    begin
      Cyclid.logger = Logger.new(STDERR)
    rescue StandardError => ex
      abort "Failed to initialize: #{ex}"
    end
  end
end

require 'cyclid/plugins'

include Cyclid::API

Cyclid.logger.debug "Plugins registered: #{Cyclid.plugins}"

# Create a Builder
builder = Cyclid.plugins.find('mist', Cyclid::API::Plugins::Builder)
mist = builder.new(os: 'Ubuntu 14.04')
Cyclid.logger.debug "got a builder: #{mist.inspect}"

build_host = mist.get
Cyclid.logger.debug "got a build host: #{build_host.inspect}"

# Try to match a transport that the host supports, to a transport we know how
# to create; transports should be listed in the order they're preferred.
transport = nil
build_host.transports.each do |t|
  Cyclid.logger.debug "Trying transport '#{t}'.."
  transport = Cyclid.plugins.find(t, Cyclid::API::Plugins::Transport)
end

abort "Couldn't find a valid transport from #{build_host.transports}" \
  unless transport

Cyclid.logger.debug 'got a valid transport'

# Connect a transport to the build host
host, username, password = build_host.connect_info
Cyclid.logger.debug "host: #{host} username: #{username} password: #{password}"

log_buffer = LogBuffer.new(nil)
ssh = transport.new(host: host, user: username, password: password, log: log_buffer)

# Run some commands
command = Cyclid.plugins.find('command', Cyclid::API::Plugins::Action)

plugin = command.new(cmd: 'ls -l', path: '/var/log')
plugin.prepare(transport: ssh, ctx: {})
success, rc = plugin.perform(log_buffer)

Cyclid.logger.info "action failed with exit status #{rc}" \
  unless success

plugin = command.new(cmd: 'ls -z', path: '/var/log')
plugin.prepare(transport: ssh, ctx: {})
success, rc = plugin.perform(log_buffer)

Cyclid.logger.info "action failed with exit status #{rc}" \
  unless success

# Drop the build host; the transport needs to be active, still
mist.release(ssh, build_host)

# Close the transport
ssh.close

# Dump the log
puts "========="
puts log_buffer.log
