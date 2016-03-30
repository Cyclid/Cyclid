# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all User related API endpoints
    module Users
      # API endpoints for the User collection
      # @api REST
      module Collection
        # @!group Users

        # @!method users
        # @overload GET /users
        # @macro rest
        # Get all of the users.
        # @return List of users
        # @example Get a list of users
        #   GET /users => [{
        #                     "id": 1,
        #                     "username": "user1",
        #                     "email": "user1@example.com"
        #                   },
        #                   {
        #                     "id": 2,
        #                     "username": "user2",
        #                     "email": "user2@example.com"
        #                   }]
        # @see get_users_user

        # @!method post_users(body)
        # @overload POST /users
        # @macro rest
        # Create a new user. Note that only *one* of 'password' or 'new_password' should be
        # passed.
        # @param [JSON] body New user
        # @option body [String] username Username of the new user
        # @option body [String] email Users email address
        # @option body [String] password Bcrypt2 encrypted password
        # @option body [String] new_password Password in plain text, which will be encrypted
        #   before being stored in the databaase.
        # @option body [String] secret HMAC signing secret. This should be a suitably long
        #   random string.
        # @return [200] User was created successfully
        # @return [400] The user definition is invalid
        # @return [409] An user with that name already exists
        # @example Create a new user with an encrypted password
        #   POST /users <= {"username": "user1",
        #                   "email": "user1@example.com",
        #                   "password": "<Bcrypt2 encrypted password>"}

        # @!endgroup

        # Sinatra callback
        # @private
        def self.registered(app)
          include Errors::HTTPErrors

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

            payload = parse_request_body
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
