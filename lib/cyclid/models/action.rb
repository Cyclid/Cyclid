# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Model for Actions
    class Action < ActiveRecord::Base
      Cyclid.logger.debug('In the Action model')

      validates :sequence, presence: true

      belongs_to :stage
    end
  end
end
