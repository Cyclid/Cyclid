require 'sinatra'

# Top level module for the core Cyclid code.
module Cyclid
  # Base class for all API Controllers
  class ControllerBase < Sinatra::Base
    include Cyclid::Errors::HTTPErrors

    helpers do
      # Safely parse & validate the request body as JSON
      def json_request_body
        # Parse the the request
        begin
          request.body.rewind
          json = Oj.load request.body.read
        rescue Oj::ParseError => ex
          Cyclid.logger.debug ex.message
          halt_with_json_response(400, INVALID_JSON, ex.message)
        end

        # Sanity check the JSON
        halt_with_json_response(400, \
          INVALID_JSON, \
          'request body can not be empty') if json.nil?
        halt_with_json_response(400, \
          INVALID_JSON, \
          'request body is invalid') unless json.is_a?(Hash)

        return json
      end

      # Return a RESTful JSON response
      def json_response(id, description)
        Oj.dump(id: id, description: description)
      end

      # Return an HTTP error with a RESTful JSON response
      def halt_with_json_response(error, id, description)
        halt error, json_response(id, description)
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
