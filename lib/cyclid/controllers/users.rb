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

      post '/users' do
        authenticate!

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

      get '/users/:username' do
        authenticate!

        user = User.find_by(username: params[:username])
        halt_with_json_response(404, INVALID_USER,'user does not exist') \
          if user.nil?

        Cyclid.logger.debug user.organizations

        # Convert to a Hash and inject the Organization data
        user_hash = user.serializable_hash
        user_hash['organizations'] = user.organizations.map{ |org| org.name }

        user_hash = sanitize_user(user_hash)

        return user_hash.to_json
      end

      put '/users/:username' do
        authenticate!

        payload = json_request_body
        Cyclid.logger.debug payload

        user = User.find_by(username: params[:username])
        halt_with_json_response(404, INVALID_USER,'user does not exist') \
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

      delete '/users/:username' do
        authenticate!

        user = User.find_by(username: params[:username])
        halt_with_json_response(404, INVALID_USER,'user does not exist') \
          if user.nil?

        begin
          user.delete
        rescue ActiveRecord::ActiveRecordError => ex
          Cyclid.logger.debug ex.message
          halt_with_json_response(400, INVALID_JSON, ex.message)
        end

        return json_response(NO_ERROR, "user #{params['username']} deleted")
      end
    end

    # Register this controller
    Cyclid.controllers << UserController
  end
end
