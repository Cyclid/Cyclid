# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Controller for all User related API endpoints
    class UserController < ControllerBase
      # @macro [attach] sinatra.get
      #   @overload get "$1"
      # @method get_users
      # @return [String] JSON represention of all of all the users.
      # Get all of the users across all organizations.
      get '/users' do
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
      post '/users' do
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

      # @method get_users_user
      # @param [String] username Username of the user.
      # @return [String] JSON represention of the requested users.
      # Get a specific user.
      get '/users/:username' do
        authorized_as!(params[:username], Operations::READ)

        user = User.find_by(username: params[:username])
        halt_with_json_response(404, INVALID_USER, 'user does not exist') \
          if user.nil?

        Cyclid.logger.debug user.organizations

        # Convert to a Hash and inject the Organization data
        user_hash = user.serializable_hash
        user_hash['organizations'] = user.organizations.map(&:name)

        user_hash = sanitize_user(user_hash)

        return user_hash.to_json
      end

      # @method put("/users/:username")
      # @param [String] username Username of the user.
      # Modify a specific user.
      put '/users/:username' do
        authorized_as!(params[:username], Operations::WRITE)

        payload = json_request_body
        Cyclid.logger.debug payload

        user = User.find_by(username: params[:username])
        halt_with_json_response(404, INVALID_USER, 'user does not exist') \
          if user.nil?

        begin
          user.email = payload['email'] if payload.key? 'username'
          user.password = payload['password'] if payload.key? 'password'
          user.secret = payload['secret'] if payload.key? 'secret'
          user.new_password = payload['new_password'] if payload.key? 'new_password'
          user.save!
        rescue ActiveRecord::ActiveRecordError => ex
          Cyclid.logger.debug ex.message
          halt_with_json_response(400, INVALID_JSON, ex.message)
        end

        return json_response(NO_ERROR, "user #{payload['username']} modified")
      end

      # @method delete("/users/:username")
      # @param [String] username Username of the user.
      # Delete a specific user.
      delete '/users/:username' do
        authorized_as!(params[:username], Operations::ADMIN)

        user = User.find_by(username: params[:username])
        halt_with_json_response(404, INVALID_USER, 'user does not exist') \
          if user.nil?

        begin
          user.delete
        rescue ActiveRecord::ActiveRecordError => ex
          Cyclid.logger.debug ex.message
          halt_with_json_response(400, INVALID_JSON, ex.message)
        end

        return json_response(NO_ERROR, "user #{params['username']} deleted")
      end

      private

      # Remove sensitive data from the users data
      def sanitize_user(user)
        user.delete_if do |key, _value|
          key == 'password' || key == 'secret'
        end
      end
    end

    # Register this controller
    Cyclid.controllers << UserController
  end
end
