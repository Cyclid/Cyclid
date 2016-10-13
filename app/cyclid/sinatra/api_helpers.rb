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

require 'oj'
require 'yaml'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Sinatra helpers
    module APIHelpers
      # Return the raw request body
      def request_body
        request.body.rewind
        request.body.read
      end

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
