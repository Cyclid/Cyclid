require 'require_all'
require 'active_support/core_ext'

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

          # Add the (derived) plugin to the plugin registry
          def register_plugin(name)
            @name = name
            Cyclid.plugins.register(self)
          end

          # Get the configuration for the given org
          def get_config(org)
            config = org.plugin_configs.find_by(plugin: @name)
            if config.nil?
              # No config currently exists; create a new default config
              config = PluginConfig.new(plugin: @name,
                                        version: '1.0.0',
                                        config: default_config)
              config.save!

              org.plugin_configs << config
            end

            # Convert the model to a hash and add the config schema
            config_hash = config.serializable_hash
            config_hash[:schema] = config_schema

            return config_hash
          rescue StandardError => ex
            Cyclid.logger.error "couldn't get/create plugin config for #{@name}: #{ex}"
            raise
          end

          # Set the configuration for the given org
          def set_config(config, org)
            raise "this plugin doesn't have a setable config"
          end

          # Provide the default configuration state that should be used when creating a new config
          def default_config
            {}
          end

          # Get the schema for the configuration data that the plugin stores
          def config_schema
            {}
          end
        end
      end
    end
  end
end

require_rel 'plugins/*.rb'
