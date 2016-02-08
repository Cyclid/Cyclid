require 'sinatra'

# Top level module for the core Cyclid code.
module Cyclid
  # Base class for all API Controllers
  class ControllerBase < Sinatra::Base
    helpers do
      # Safely parse & validate the request body as JSON
      def json_request_body
        # Parse the JSON from the request
        begin
          request.body.rewind
          json = Oj.load request.body.read
        rescue
          halt 400
        end

        halt 400 if json.nil?
        halt 400 unless json.is_a?(Hash)

        return json
      end
    end
  end
end

# Load any and all controllers
require_rel 'controllers/*.rb'

# Top level module for the core Cyclid code.
module Cyclid
  # Sintra application for the REST API
  class API < Sinatra::Application
    # Set up the Sinatra configuration
    configure do
      enable :logging
    end

    # Register all of the controllers with Sinatra
    Cyclid.controllers.each do |controller|
      Cyclid.logger.debug "Using Sinatra controller #{controller}"
      use controller
    end
  end
end
