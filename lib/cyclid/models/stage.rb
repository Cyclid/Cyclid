# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Model for Stages
    class Stage < ActiveRecord::Base
      Cyclid.logger.debug('In the Stage model')

      validates :name, presence: true
      validates :version, presence: true

      validates_uniqueness_of :name
      validates_format_of :version, with: /\A\d+.\d+.\d+.?\d*\z/

      belongs_to :organization
      has_many :actions
    end
  end
end
