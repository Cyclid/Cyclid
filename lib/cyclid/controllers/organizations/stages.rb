# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for Organization Stages
      module Stages
        def self.registered(app)
          include Errors::HTTPErrors

          # @macro [attach] sinatra.get
          #   @overload get "$1"
          # @method get_organizations_organization_stages
          # @return [String] JSON represention of all the stages with the organization.
          # Get all of the stages.
          app.get do
            authorized_for!(params[:name], Operations::READ)

            # Retrieve the stage data in a form we can more easily manipulate so
            # that we can sanitize it
            stages = Stage.all_as_hash

            # Clean it up
            stages.map! do |stage|
              sanitize_stage(stage)
            end

            return stages.to_json
          end

          # @macro [attach] sinatra.post
          #   @overload post "$1"
          # @method post_organizations_organization_stages
          # Create a new stage.
          app.post do
            authorized_for!(params[:name], Operations::ADMIN)

            payload = json_request_body
            Cyclid.logger.debug payload

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            begin
              stage = Stage.new

              stage.name = payload['name']
              stage.version = payload['version'] if payload.key? 'version'
              stage.organization = org

              # XXX: Create & seralize the actions

              stage.save!
            rescue ActiveRecord::ActiveRecordError, \
                   ActiveRecord::UnknownAttributeError => ex

              Cyclid.logger.debug ex.message
              halt_with_json_response(400, INVALID_JSON, ex.message)
            end
          end
        end
      end
    end
  end
end
