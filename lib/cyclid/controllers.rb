require 'sinatra'
require 'warden'

# Top level module for the core Cyclid code.
module Cyclid
  # Base class for all API Controllers
  class ControllerBase < Sinatra::Base
    include Cyclid::Errors::HTTPErrors

    # The API always returns JSON
    before do
      content_type :json
    end

    helpers do
      # Safely parse & validate the request body as JSON
      def json_request_body
        # Parse the the request
        begin
          request.body.rewind
          json = Oj.load request.body.read
        rescue Oj::ParseError => ex
          Cyclid.logger.debug ex.message
          halt_with_json_response(400, INVALID_JSON, ex.message)
        end

        # Sanity check the JSON
        halt_with_json_response(400, \
          INVALID_JSON, \
          'request body can not be empty') if json.nil?
        halt_with_json_response(400, \
          INVALID_JSON, \
          'request body is invalid') unless json.is_a?(Hash)

        return json
      end

      # Return a RESTful JSON response
      def json_response(id, description)
        Oj.dump(id: id, description: description)
      end

      # Return an HTTP error with a RESTful JSON response
      def halt_with_json_response(error, id, description)
        halt error, json_response(id, description)
      end

      # Call the Warden authenticate! method
      def authenticate!
        env['warden'].authenticate!
      end

      # Authenticate the user, then ensure that the user is an admin
      def authorized!
        authenticate!

        user = env['warden'].user
        unless user.admin # rubocop:disable Style/GuardClause
          Cyclid.logger.info "unauthorized: #{user.username}"
          halt_with_json_response(401, AUTH_FAILURE, 'unauthorized')
        end
      end

      # Current User object from the session
      def current_user
        env['warden'].user
      end
    end

    # Configure Warden to authenticate
    use Warden::Manager do |config|
      config.serialize_into_session{ |user| user.id }
      config.serialize_from_session{ |id| User.find_by_id(id) }

      config.scope_defaults :default,
                            strategies: [:basic, :hmac, :api_token],
                            action: '/unauthenticated'

      config.failure_app = self
    end

    Warden::Manager.before_failure do |env, _opts|
      env['REQUEST_METHOD'] = 'POST'
    end

    # Authenticate via. HTTP Basic auth.
    Warden::Strategies.add(:basic) do
      def valid?
        request.env['HTTP_AUTHORIZATION'].is_a? String and \
          request.env['HTTP_AUTHORIZATION'] =~ %r{^Basic .*$}
      end

      def authenticate!
        begin
          authorization = request.env['HTTP_AUTHORIZATION']
          digest = authorization.match(%r{^Basic (.*)$}).captures.first

          user_pass = Base64.decode64(digest)
          username, password = user_pass.split(':')
        rescue
          fail! 'invalid digest'
        end

        user = User.find_by(username: username)
        if user.nil?
          fail! 'invalid user'
        elsif BCrypt::Password.new(user.password).is_password? password
          success! user
        else
          fail! 'invalid user'
        end
      end
    end

    # Authenticate via. HMAC
    Warden::Strategies.add(:hmac) do
      def valid?
        request.env['HTTP_AUTH_USER'].is_a? String and \
          request.env['HTTP_AUTHORIZATION'].is_a? String and \
          request.env['HTTP_AUTHORIZATION'] =~ %r{^HMAC .*$}
      end

      def authenticate!
        user = User.find_by(username: request.env['HTTP_AUTH_USER'])
        if user.nil?
          fail! 'invalid user'
        else
          begin
            authorization = request.env['HTTP_AUTHORIZATION']
            hmac = authorization.match(%r{^HMAC (.*)$}).captures.first
          rescue
            fail! 'invalid HMAC'
          end

          begin
            method = request.env['REQUEST_METHOD']
            path = request.env['PATH_INFO']
            date = request.env['HTTP_DATE']

            Cyclid.logger.debug "user=#{user.username} method=#{method} path=#{path} date=#{date} HMAC=#{hmac}"

            signer = Cyclid::HMAC::Signer.new
            if signer.validate_signature(hmac, {secret: user.secret, method: method, path: path, date: date})
              success! user
            else
              fail! 'invalid user'
            end
          rescue Exception => ex
            Cyclid.logger.debug "failure during HMAC authentication: #{ex}"
            fail! 'invalid headers'
          end
        end
      end
    end

    # Authenticate via. an API token
    Warden::Strategies.add(:api_token) do
      def valid?
        request.env['HTTP_AUTH_USER'].is_a? String and \
          request.env['HTTP_AUTHORIZATION'].is_a? String and \
          request.env['HTTP_AUTHORIZATION'] =~ %r{^Token .*$}
      end

      def authenticate!
        user = User.find_by(username: request.env['HTTP_AUTH_USER'])
        if user.nil?
          fail! 'invalid user'
        else
            authorization = request.env['HTTP_AUTHORIZATION']
            token = authorization.match(%r{^Token (.*)$}).captures.first

            if user.secret == token
              success! user
            else
              fail! 'invalid user'
            end
        end
      end
    end

    post '/unauthenticated' do
      content_type :json
      # Stop Warden from calling this endpoint again in an endless loop when
      # it sees the 401 response
      env['warden'].custom_failure!
      halt_with_json_response(401, AUTH_FAILURE, 'invalid username or password')
    end
  end
end

# Load any and all controllers
require_rel 'controllers/*.rb'

# Top level module for the core Cyclid code.
module Cyclid
  # Sintra application for the REST API
  class API < Sinatra::Application
    # Set up the Sinatra configuration
    configure do
      enable :logging
    end

    # Register all of the controllers with Sinatra
    Cyclid.controllers.each do |controller|
      Cyclid.logger.debug "Using Sinatra controller #{controller}"
      use controller
    end
  end
end
