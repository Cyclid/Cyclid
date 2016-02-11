# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Controller for all User related API endpoints
    class UserController < ControllerBase
      get '/users' do
        authenticate!

        # Retrieve the user data in a form we can more easily manipulate so
        # that we can sanitize it
        users = User.all_as_hash

        # Remove any sensitive data
        users.map! do |user|
          user.delete_if do |key, _value|
            key == 'password' || key == 'secret'
          end
        end

        return users.to_json
      end
    end

    # Register this controller
    Cyclid.controllers << UserController
  end
end
