require_rel 'organizations/*.rb'

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Controller for all Organization related API endpoints
    class OrganizationController < ControllerBase
      helpers do
        # Clean up stage data
        def sanitize_stage(stage)
          stage.delete_if do |key, _value|
            key == 'organization_id'
          end
        end

        # Clean up action data
        def sanitize_action(action)
          action.delete_if do |key, _value|
            key == 'stage_id'
          end
        end
      end

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
