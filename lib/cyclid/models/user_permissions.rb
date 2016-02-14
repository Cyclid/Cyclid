# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Model for UserPermissions
    class Userpermission < ActiveRecord::Base
      Cyclid.logger.debug('In the Userpermission model')

      belongs_to :user
      belongs_to :organization
    end
  end
end
