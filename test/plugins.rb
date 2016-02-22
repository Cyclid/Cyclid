#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

abort 'Need to pass hostname, username & password' if ARGV.size < 3

require 'require_all'
require 'logger'
require 'active_record'

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

require 'cyclid/transport'
require 'cyclid/plugins'

include Cyclid::API

Cyclid.logger.debug "Plugins registered: #{Cyclid.plugins}"

log_buffer = LogBuffer.new(nil)
transport = Transport.new(ARGV[0], ARGV[1], log: log_buffer, password: ARGV[2])

command = Cyclid.plugins.find('command', Cyclid::API::Plugins::Action)
plugin = command.new(command: 'ls -l', cwd: '/var/log', transport: transport, ctx: {})
plugin.perform(log_buffer)

transport.close
