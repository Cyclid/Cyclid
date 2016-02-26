# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Model for Users
    class JobRecord < ActiveRecord::Base
      Cyclid.logger.debug('In the JobRecod model')
    end
  end
end
