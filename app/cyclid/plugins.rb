# frozen_string_literal: true
# Copyright 2016 Liqwyd Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'require_all'
require 'active_support/core_ext'

require_relative 'health_helpers'

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

          # Returns the 'human' name for the plugin type
          def human_name
            'base'
          end

          # Add the (derived) plugin to the plugin registry
          def register_plugin(name)
            @name = name
            Cyclid.plugins.register(self)
          end

          # Does this plugin support configuration data?
          def config?
            false
          end

          # Get the configuration for the given org
          def get_config(org)
            # If the organization was passed by name, convert it into an Organization object
            org = Organization.find_by(name: org) if org.is_a? String
            raise 'organization does not exist' if org.nil?

            # XXX Plugins of different types can have the same name; we need to
            # add a 'type' field and also find by the type.
            config = org.plugin_configs.find_by(plugin: @name)
            if config.nil?
              # No config currently exists; create a new default config
              config = PluginConfig.new(plugin: @name,
                                        version: '1.0.0',
                                        config: Oj.dump(default_config.stringify_keys))
              config.save!

              org.plugin_configs << config
            end

            # Convert the model to a hash, add the config schema, and convert the JSON config
            # blob back into a hash
            config_hash = config.serializable_hash
            config_hash['schema'] = config_schema
            config_hash['config'] = Oj.load(config.config)

            return config_hash
          rescue StandardError => ex
            Cyclid.logger.error "couldn't get/create plugin config for #{@name}: #{ex}"
            raise
          end

          # Set the configuration for the given org
          def set_config(new_config, org)
            new_config.stringify_keys!

            config = org.plugin_configs.find_by(plugin: @name)
            if config.nil?
              # No config currently exists; create a new default config
              config = PluginConfig.new(plugin: @name,
                                        version: '1.0.0',
                                        config: Oj.dump(default_config.stringify_keys))
              config.save!

              org.plugin_configs << config
            end

            # Let the plugin validate & merge the changes into the config hash
            config_hash = config.serializable_hash
            current_config = config_hash['config']
            Cyclid.logger.debug "current_config=#{current_config}"
            merged_config = update_config(Oj.load(current_config), new_config)

            raise 'plugin rejected the configuration' if merged_config == false

            Cyclid.logger.debug "merged_config=#{merged_config}"

            # Update the stored configuration
            config.config = Oj.dump(merged_config.stringify_keys)
            config.save!
          end

          # Validite the given configuration items and merge them into the correct configuration,
          # returning an updated complete configuration that can be stored.
          def update_config(_current, _new)
            return false
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

# Load all plugins from Gems
Gem.find_files('cyclid/plugins/**/*.rb').each do |path|
  require path
end
