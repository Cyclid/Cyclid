require 'require_all'
require 'logger'

require 'cyclid/config'
require 'cyclid/plugin_registry'

# Top level module for the core Cyclid code.
module Cyclid
  class << self
    attr_accessor :config, :controllers, :plugins, :dispatcher, :builder, :logger

    config_path = ENV['CYCLID_CONFIG'] || File.join(%w(/ etc cyclid config))
    Cyclid.config = API::Config.new(config_path)

    Cyclid.controllers = []
    Cyclid.plugins = API::Plugins::Registry.new

    begin
      Cyclid.logger = if Cyclid.config.log.casecmp('stderr').zero?
                        Logger.new(STDERR)
                      else
                        Logger.new(Cyclid.config.log)
                      end
    rescue StandardError => ex
      abort "Failed to initialize: #{ex}"
    end
  end
end

require_relative 'db'

require 'cyclid/monkey_patches'
require 'cyclid/constants'
require 'cyclid/errors'
require 'cyclid/models'
require 'cyclid/hmac'
require 'cyclid/plugins'
require 'cyclid/job'
require 'cyclid/controllers'

dispatcher = Cyclid.plugins.find(Cyclid.config.dispatcher, Cyclid::API::Plugins::Dispatcher)
abort "Could not find dispatcher '#{Cyclid.config.dispatcher}'" if dispatcher.nil?
Cyclid.dispatcher = dispatcher.new

Cyclid.builder = Cyclid.plugins.find(Cyclid.config.builder, Cyclid::API::Plugins::Builder)
abort "Could not find builder '#{Cyclid.config.builder}'" if Cyclid.builder.nil?
