require 'bcrypt'

# Top level module for the core Cyclid code.
module Cyclid
  # Model for Users 
  class User < ActiveRecord::Base
    Cyclid.logger.debug('In the User model')

    validates :username, presence: true
    validates :email, presence: true

    validates_uniqueness_of :username

    attr_accessor :new_password

    before_save :hash_new_password, :if => :password_changed?

    def password_changed?
      !@new_password.blank?
    end

    def hash_new_password
      self.password = BCrypt::Password.create(@new_password)
    end
  end
end
