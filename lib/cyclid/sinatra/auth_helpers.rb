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

      # Authenticate the user, then ensure that the user is authorized for
      # the given organization and operation
      def authorized_for!(org_name, operation)
        authenticate!

        user = current_user

        # XXX: Return immediately if the user is a SuperAdmin

        begin
          organization = user.organizations.find_by(name: org_name)
          Cyclid.logger.debug "organization: #{organization.name}"
          halt_with_json_response(401, Errors::HTTPErrors::AUTH_FAILURE, 'unauthorized') \
            if organization.nil?
        rescue Exception => ex # XXX: Use a more specific rescue
          Cyclid.logger.info "authorization failed: #{ex}"
          halt_with_json_response(401, Errors::HTTPErrors::AUTH_FAILURE, 'unauthorized')
        end

        # XXX: Check what Roles are applied to the user for this Org & match
        # against operation

        Cyclid.logger.debug "#{user.username} authorized for #{operation} on #{org_name}"
      end

      # Current User object from the session
      def current_user
        env['warden'].user
      end
    end
  end
end
