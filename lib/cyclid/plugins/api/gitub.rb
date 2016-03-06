# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Container for the Sinatra related controllers modules
      module ApiExtension
        # Github plugin method callbacks
        module GithubMethods
          include Methods

          def post(data)
            Cyclid.logger.debug 'in GithubMethods::post: #{data}'
            return_failure(405, 'not implemented')
          end
        end
      end

      # API extension for Github hooks 
      class Github < Api
        def self.controller
          return ApiExtension::Controller.new(ApiExtension::GithubMethods)
        end

        # Register this plugin
        register_plugin 'github'
      end
    end
  end
end
