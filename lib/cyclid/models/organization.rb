# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Model for Organizations
    class Organization < ActiveRecord::Base
      Cyclid.logger.debug('In the Organization model')

      validates :name, presence: true
      validates :owner_email, presence: true

      validates_uniqueness_of :name
    end
  end
end
