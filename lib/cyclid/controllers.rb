require 'sinatra'

# Load any and all controllers
require_rel 'controllers/*.rb'

# Top level module for the core Cyclid code.
module Cyclid
  # Sintra application for the REST API
  class API < Sinatra::Base
    # Set up the Sinatra configuration
    configure do
      enable :logging
      enable :sessions
    end

    # Register all of the controllers with Sinatra
    Cyclid.controllers.each do |controller|
      Cyclid.logger.debug "Using Sinatra controller #{controller}"
      use controller
    end
  end
end
