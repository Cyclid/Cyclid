# Top level module for the core Cyclid code.
module Cyclid
  # Sinatra helpers
  module Helpers
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

    # Call the Warden authenticate! method
    def authenticate!
      env['warden'].authenticate!
    end

    # Authenticate the user, then ensure that the user is an admin
    def authorized!
      authenticate!

      user = env['warden'].user
      unless user.admin # rubocop:disable Style/GuardClause
        Cyclid.logger.info "unauthorized: #{user.username}"
        halt_with_json_response(401, AUTH_FAILURE, 'unauthorized')
      end
    end

    # Current User object from the session
    def current_user
      env['warden'].user
    end
  end
end
