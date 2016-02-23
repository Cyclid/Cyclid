# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Model for Steps
    class Step < ActiveRecord::Base
      Cyclid.logger.debug('In the Step model')

      validates :sequence, presence: true

      belongs_to :stage
    end
  end
end
