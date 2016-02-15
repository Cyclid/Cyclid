require 'require_all'
require 'logger'

# Top level module for the core Cyclid code.
module Cyclid
  class << self
    attr_accessor :controllers, :logger

    Cyclid.controllers = []

    begin
      Cyclid.logger = Logger.new(STDERR)
    rescue Exception => ex
      abort "Failed to initialize: #{ex}"
    end
  end
end

require_relative 'db'

require 'cyclid/errors'
require 'cyclid/models'
require 'cyclid/hmac'
require 'cyclid/controllers'
