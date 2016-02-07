require 'oj'

# Top level module for all of the core Cyclid code.
module Cyclid
  # Controller for all Organization related API endpoints
  class OrganizationController < Sinatra::Base
    get '/organization' do
      content_type :json

      return Oj.dump([{name: 'Test organization'},{name: 'S.H.I.E.L.D'}])
    end
  end

  # Register this controller
  Cyclid.controllers << OrganizationController
end
