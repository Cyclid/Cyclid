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
          @types = []
        end

        # Add a plugin to the registry
        def register(plugin)
          # XXX Perform sanity checks
          @plugins << plugin

          # Maintain a human<->type mapping
          human_name = plugin.human_name
          @types << { human: human_name, type: plugin.superclass }
        end

        # Find a plugin from the registry
        def find(name, type)
          object_type = nil

          # Convert a human name to a type, if required
          if type.is_a? String
            @types.each do |registered_type|
              next unless registered_type[:human] == type

              object_type = registered_type[:type]
              break
            end
          else
            object_type = type
          end

          raise "couldn't map plugin type #{type}" if object_type.nil?

          @plugins.each do |plugin|
            return plugin if plugin.name == name && plugin.superclass == object_type
          end
          return nil
        end

        # Return a list of all plugins of a certain type
        def all(type = nil)
          list = []
          @plugins.each do |plugin|
            list << plugin if plugin.superclass == type or type.nil?
          end
          return list
        end
      end
    end
  end
end
