# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Model for Stages
    class Stage < ActiveRecord::Base
      Cyclid.logger.debug('In the Stage model')

      class << self
        # Return the collection of Stages as an array of Hashes (instead
        # of Stage objects)
        def all_as_hash
          all.to_a.map(&:serializable_hash)
        end
      end

      validates :name, presence: true
      validates :version, presence: true

      validates_uniqueness_of :name, scope: :version
      validates_format_of :version, with: /\A\d+.\d+.\d+.?\d*\z/

      belongs_to :organization
      has_many :actions
    end
  end
end
