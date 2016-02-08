#require 'activerecord'

# Top level module for the core Cyclid code.
module Cyclid
  # Model for Organizations
  class Organization < ActiveRecord::Base
    Cyclid.logger.debug('In the Organization model')
  end
end
