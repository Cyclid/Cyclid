require 'require_all'
require 'logger'

# Top level module for the core Cyclid code.
module Cyclid
  class << self
    attr_accessor :controllers, :logger
  end
end

Cyclid.controllers = []
begin
  Cyclid.logger = Logger.new(STDERR)
rescue
  abort "Failed to initialize: #{ex}"
end

require 'cyclid/models'
require 'cyclid/controllers'
