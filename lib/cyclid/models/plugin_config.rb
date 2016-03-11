# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Model for PluginConfigs
    class PluginConfig < ActiveRecord::Base
      belongs_to :organization
    end
  end
end
