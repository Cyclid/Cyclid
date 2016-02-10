# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Sinatra Warden AuthN/AuthZ helpers
    module AuthHelpers
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
end
