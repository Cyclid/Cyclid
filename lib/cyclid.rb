require 'require_all'
require 'logger'

# Top level module for the core Cyclid code.
module Cyclid
  class << self
    attr_accessor :controllers, :plugins, :logger

    Cyclid.controllers = []
    Cyclid.plugins = []

    begin
      Cyclid.logger = Logger.new(STDERR)
    rescue StandardError => ex
      abort "Failed to initialize: #{ex}"
    end
  end
end

require_relative 'db'

require 'cyclid/errors'
require 'cyclid/models'
require 'cyclid/hmac'
require 'cyclid/plugins'
require 'cyclid/controllers'
