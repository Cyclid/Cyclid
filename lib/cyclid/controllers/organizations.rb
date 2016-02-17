require_rel 'organizations/*.rb'

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Controller for all Organization related API endpoints
    class OrganizationController < ControllerBase
      register Sinatra::Namespace

      namespace '/organizations' do
        register Organizations::Collection

        namespace '/:name' do
          register Organizations::Document

          namespace '/members' do
            register Organizations::Members
          end

          namespace '/stages' do
            register Organizations::Stages
          end
        end
      end
    end

    Cyclid.controllers << OrganizationController
  end
end
