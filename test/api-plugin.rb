# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Container for the Sinatra related controllers modules
      module ApiExtension
        # Github plugin method callbacks
        module TestMethods
          include Methods

          # Return a reference to the plugin that is associated with this
          # controller; used by the lower level code.
          def controller_plugin
            Cyclid.plugins.find('test', Cyclid::API::Plugins::Api)
          end

          # HTTP GET callback
          def get(headers, config)
            Cyclid.logger.debug "Here I am in the test plugin GET callback"
            return_failure(400, 'this is a test plugin')
          end

          # HTTP POST callback
          def post(data, headers, config)
            Cyclid.logger.debug "Here I am in the test plugin POST callback"
            return_failure(400, 'this is a test plugin')
          end
        end
      end 

      # API extension for Test hooks
      class Test < Api
        def self.controller
          return ApiExtension::Controller.new(ApiExtension::TestMethods)
        end

        # Register this plugin
        register_plugin 'test'
      end
    end
  end
end
