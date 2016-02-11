# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Controller for all User related API endpoints
    class UserController < ControllerBase
      def sanitize_user(user)
        user.delete_if do |key, _value|
          key == 'password' || key == 'secret'
        end
      end

      get '/users' do
        authenticate!

        # Retrieve the user data in a form we can more easily manipulate so
        # that we can sanitize it
        users = User.all_as_hash

        # Remove any sensitive data
        users.map! do |user|
          sanitize_user(user)
        end

        return users.to_json
      end

      get '/users/:username' do
        authenticate!

        user = User.find_by(username: params[:username])
        halt_with_json_response(404, INVALID_USER,'user does not exist') \
          if user.nil?

        user = sanitize_user(user.serializable_hash)
        return user.to_json
      end
    end

    # Register this controller
    Cyclid.controllers << UserController
  end
end
