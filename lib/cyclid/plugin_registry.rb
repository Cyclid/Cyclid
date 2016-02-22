# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      class Registry
        def initialize
          @plugins = []
        end

        def register(plugin)
          # XXX Perform sanity checks
          @plugins << plugin
        end

        def find(name, type)
          @plugins.each do |plugin|
            return plugin if plugin.name == name && plugin.superclass == type
          end
        end
      end
    end
  end
end
