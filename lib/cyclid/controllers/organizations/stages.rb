# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for Organization Stages
      module Stages
        def self.registered(app)
          # @macro [attach] sinatra.get
          #   @overload get "$1"
          # @method get_organizations_organization_stages
          # @return [String] JSON represention of all the stages with the organization.
          # Get all of the stages.
          app.get do
            authorized_admin!(Operations::READ)

            return Stage.all.to_json
          end
        end
      end
    end
  end
end
