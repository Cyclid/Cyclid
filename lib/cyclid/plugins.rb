require 'require_all'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Base class for Plugins
      class Base
        class << self
          attr_reader :name

          def register_plugin(name)
            @name=name
            Cyclid.plugins.register(self)
          end
        end
      end
    end
  end
end
 
require_rel 'plugins/*.rb'
