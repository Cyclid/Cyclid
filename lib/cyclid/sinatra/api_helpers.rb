# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Sinatra helpers
    module APIHelpers
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
    end
  end
end
