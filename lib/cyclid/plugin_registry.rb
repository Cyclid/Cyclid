# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Intelligent system-wide registry of available plugins with helper
      # methods to find them again
      class Registry
        def initialize
          @plugins = []
        end

        # Add a plugin to the registry
        def register(plugin)
          # XXX Perform sanity checks
          @plugins << plugin
        end

        # Find a plugin from the registry
        def find(name, type)
          @plugins.each do |plugin|
            Cyclid.logger.debug plugin.name
            return plugin if plugin.name == name && plugin.superclass == type
          end
          return nil
        end
      end
    end
  end
end
