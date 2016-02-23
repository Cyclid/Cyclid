require 'bcrypt'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Model for Users
    class User < ActiveRecord::Base
      Cyclid.logger.debug('In the User model')

      class << self
        # Return the collection of Users as an array of Hashes (instead
        # of User objects)
        def all_as_hash
          all.to_a.map(&:serializable_hash)
        end
      end

      validates :username, presence: true
      validates :email, presence: true

      validates_uniqueness_of :username

      has_and_belongs_to_many :organizations
      has_many :userpermissions

      # Allow an unencryped password to be passed in via. new_password and
      # ensure it is encrypted into password when the record is saved
      attr_accessor :new_password

      before_save :hash_new_password, if: :password_changed?

      # Check if the new_password attribute has changed
      def password_changed?
        !@new_password.blank?
      end

      # Generate a BCrypt2 password from the plaintext
      def hash_new_password
        self.password = BCrypt::Password.create(@new_password)
      end
    end
  end
end
