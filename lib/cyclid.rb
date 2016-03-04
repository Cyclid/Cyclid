require 'require_all'
require 'logger'

require 'cyclid/plugin_registry'

# Top level module for the core Cyclid code.
module Cyclid
  class << self
    attr_accessor :controllers, :plugins, :dispatcher, :builder, :logger

    Cyclid.controllers = []
    Cyclid.plugins = API::Plugins::Registry.new

    begin
      Cyclid.logger = Logger.new(STDERR)
    rescue StandardError => ex
      abort "Failed to initialize: #{ex}"
    end
  end
end

require_relative 'db'

require 'cyclid/constants'
require 'cyclid/errors'
require 'cyclid/models'
require 'cyclid/hmac'
require 'cyclid/plugins'
require 'cyclid/job'
require 'cyclid/controllers'

dispatcher = Cyclid.plugins.find('local', Cyclid::API::Plugins::Dispatcher)
Cyclid.dispatcher = dispatcher.new

Cyclid.builder = Cyclid.plugins.find('mist', Cyclid::API::Plugins::Builder)
