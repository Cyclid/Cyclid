require 'oj'
require 'yaml'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Sinatra helpers
    module APIHelpers
      # Safely parse & validate the request body
      def parse_request_body
        # Parse the the request
        begin
          request.body.rewind

          if request.content_type == 'application/json' or \
             request.content_type == 'text/json'

            data = Oj.load request.body.read
          elsif request.content_type == 'application/x-yaml' or \
                request.content_type == 'text/x-yaml'

            data = YAML.load request.body.read
          else
            halt_with_json_response(415, \
                                    Errors::HTTPErrors::INVALID_JSON, \
                                    "unsupported content type #{request.content_type}")
          end
        rescue Oj::ParseError, YAML::Exception => ex
          Cyclid.logger.debug ex.message
          halt_with_json_response(400, Errors::HTTPErrors::INVALID_JSON, ex.message)
        end

        # Sanity check the request
        halt_with_json_response(400, \
                                Errors::HTTPErrors::INVALID_JSON, \
                                'request body can not be empty') if data.nil?
        halt_with_json_response(400, \
                                Errors::HTTPErrors::INVALID_JSON, \
                                'request body is invalid') unless data.is_a?(Hash)

        return data
      end

      # Return a RESTful JSON response
      def json_response(id, description)
        Oj.dump('id' => id, 'description' => description)
      end
    end
  end
end
