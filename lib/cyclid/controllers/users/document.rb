# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all User related API endpoints
    module Users
      # API endpoints for a single Organization document
      module Document
        # Sinatra callback
        def self.registered(app)
          include Errors::HTTPErrors

          # @method get_users_user
          # @param [String] username Username of the user.
          # @return [String] JSON represention of the requested users.
          # Get a specific user.
          app.get do
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
          app.put do
            authorized_as!(params[:username], Operations::WRITE)

            payload = parse_request_body
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
          app.delete do
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
        end
      end
    end
  end
end
