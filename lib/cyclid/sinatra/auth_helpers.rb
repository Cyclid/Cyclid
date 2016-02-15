# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Some constants to identify types of API operation
    module Operations
      # Read operations
      READ = 1
      # Write (Create, Update, Delete) operations
      WRITE = 2
      # Administrator operations
      ADMIN = 3
    end

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

        # Promote the organization to 'admins' if the user is a SuperAdmin
        org_name = 'admins' if is_super_admin?(user)

        begin
          organization = user.organizations.find_by(name: org_name)
          halt_with_json_response(401, Errors::HTTPErrors::AUTH_FAILURE, 'unauthorized') \
            if organization.nil?
          Cyclid.logger.debug "authorized_for! organization: #{organization.name}"

          # Check what Permissions are applied to the user for this Org & match
          # against operation
          permissions = user.userpermissions.find_by(organization: organization)
          Cyclid.logger.debug "authorized_for! #{permissions.inspect}"

          # Admins have full authority, regardless of the operation
          return true if permissions.admin
          return true if operation == Operations::WRITE && permissions.write
          return true if operation == Operations::READ && (permissions.write || permissions.read)

          Cyclid.logger.info "user #{user.username} is not authorized for operation #{operation}"

          halt_with_json_response(401, Errors::HTTPErrors::AUTH_FAILURE, 'unauthorized')
        rescue Exception => ex # XXX: Use a more specific rescue
          Cyclid.logger.info "authorization failed: #{ex}"
          halt_with_json_response(401, Errors::HTTPErrors::AUTH_FAILURE, 'unauthorized')
        end
      end

      # Authenticate the user, then ensure that the user is an admin and
      # authorized for the resource for the given username & operation
      def authorized_admin!(operation)
        authorized_for!('admins', operation)
      end

      # Authenticate the user, then ensure that the user is authorized for the
      # resource for the given username & operation
      def authorized_as!(username, operation)
        authenticate!

        user = current_user

        # Users are always authorized for any operation on their own data
        return true if user.username == username

        # Super Admins may be authorized, depending on the operation
        if is_super_admin?(user)
          begin
            organization = user.organizations.find_by(name: 'admins')
            permissions = user.userpermissions.find_by(organization: organization)
            Cyclid.logger.debug permissions

            # Admins have full authority, regardless of the operation
            return true if permissions.admin
            return true if operation == Operations::WRITE && permissions.write
            return true if operation == Operations::READ && (permissions.write || permissions.read)
          rescue Exception => ex # XXX: Use a more specific rescue
            Cyclid.logger.info "authorization failed: #{ex}"
            halt_with_json_response(401, Errors::HTTPErrors::AUTH_FAILURE, 'unauthorized')
          end

        end

        halt_with_json_response(401, Errors::HTTPErrors::AUTH_FAILURE, 'unauthorized')
      end

      # Check if the given user is a Super Admin; any user that belongs to the
      # 'admins' organization is a super admin
      def is_super_admin?(user)
        user.organizations.exists?(name: 'admins')
      end

      # Current User object from the session
      def current_user
        env['warden'].user
      end
    end
  end
end
