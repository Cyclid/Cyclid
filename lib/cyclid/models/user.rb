# Top level module for the core Cyclid code.
module Cyclid
  # Model for Users 
  class User < ActiveRecord::Base
    Cyclid.logger.debug('In the User model')

    validates :username, presence: true
    validates :email, presence: true

    validates_uniqueness_of :username
  end
end
