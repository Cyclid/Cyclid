#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

abort 'Need to pass hostname, username & password' if ARGV.size < 3

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

log_buffer = LogBuffer.new(nil)

transport = Cyclid.plugins.find('ssh', Cyclid::API::Plugins::Transport)
ssh = transport.new(host: ARGV[0], user: ARGV[1], password: ARGV[2], log: log_buffer)

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

ssh.close
