require 'sinatra'
require 'warden'

require_relative 'sinatra/warden/strategies/basic'
require_relative 'sinatra/warden/strategies/hmac'
require_relative 'sinatra/warden/strategies/api_token'

require_relative 'sinatra/helpers'

# Top level module for the core Cyclid code.
module Cyclid
  # Base class for all API Controllers
  class ControllerBase < Sinatra::Base
    include Cyclid::Errors::HTTPErrors

    # The API always returns JSON
    before do
      content_type :json
    end

    helpers Helpers

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

    include Cyclid::Strategies::Basic
    include Cyclid::Strategies::HMAC
    include Cyclid::Strategies::APIToken

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
