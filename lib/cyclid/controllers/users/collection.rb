# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all User related API endpoints
    module Users
      # API endpoints for the User collection
      module Collection
        def self.registered(app)
          # @macro [attach] sinatra.get
          #   @overload get "$1"
          # @method get_users
          # @return [String] JSON represention of all of all the users.
          # Get all of the users across all organizations.
          app.get do
            authorized_admin!(Operations::READ)

            # Retrieve the user data in a form we can more easily manipulate so
            # that we can sanitize it
            users = User.all_as_hash

            # Remove any sensitive data
            users.map! do |user|
              sanitize_user(user)
            end

            return users.to_json
          end

          # @macro [attach] sinatra.post
          #   @overload post "$1"
          # @method post_users
          # Create a new user.
          app.post do
            authorized_admin!(Operations::ADMIN)

            payload = json_request_body
            Cyclid.logger.debug payload

            begin
              halt_with_json_response(409, \
                                      DUPLICATE, \
                                      'a user with that name already exists') \
              if User.exists?(username: payload['username'])

              user = User.new
              user.username = payload['username']
              user.email = payload['email']
              user.password = payload['password'] if payload.key? 'password'
              user.secret = payload['secret'] if payload.key? 'secret'
              user.new_password = payload['new_password'] if payload.key? 'new_password'
              user.save!
            rescue ActiveRecord::ActiveRecordError, \
                   ActiveRecord::UnknownAttributeError => ex

              Cyclid.logger.debug ex.message
              halt_with_json_response(400, INVALID_JSON, ex.message)
            end

            return json_response(NO_ERROR, "user #{payload['username']} created")
          end
        end
      end
    end
  end
end
