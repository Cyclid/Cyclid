require_rel 'users/*.rb'

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Controller for all User related API endpoints
    class UserController < ControllerBase
      helpers do
        # Remove sensitive data from the users data
        def sanitize_user(user)
          user.delete_if do |key, _value|
            key == 'password' || key == 'secret'
          end
        end
      end

      register Sinatra::Namespace

      namespace '/users' do
        register Users::Collection

        namespace '/:username' do
          register Users::Document
        end
      end
    end

    # Register this controller
    Cyclid.controllers << UserController
  end
end
