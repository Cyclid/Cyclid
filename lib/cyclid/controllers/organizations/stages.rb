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

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # Convert each Stage to a hash & sanitize it
            stages = org.stages.all.map do |stage|
              stage_hash = sanitize_stage(stage.serializable_hash)

              # Santize each action in this stage
              actions = stage.actions.map do |action|
                sanitize_action(action.serializable_hash)
              end
              stage_hash['actions'] = actions

              stage_hash
            end

            return stages.to_json
          end

          # @macro [attach] sinatra.post
          #   @overload post "$1"
          # @method post_organizations_organization_stages
          # Create a new stage.
          app.post do
            authorized_for!(params[:name], Operations::ADMIN)

            payload = parse_request_body
            Cyclid.logger.debug payload

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            halt_with_json_response(400, INVALID_JSON, 'stage does not define any actions') \
              unless payload.key? 'actions'

            begin
              stage = Stage.new

              stage.name = payload['name']
              stage.version = payload['version'] if payload.key? 'version'
              stage.organization = org

              # Create the actions & store their serialized form
              stage.actions << create_actions(payload['actions'])

              stage.save!
            rescue ActiveRecord::ActiveRecordError, \
                   ActiveRecord::UnknownAttributeError => ex

              Cyclid.logger.debug ex.message
              halt_with_json_response(400, INVALID_JSON, ex.message)
            end
          end

          # @method get_organizations_organization_stages_stage
          # @param [String] name Name of the organization.
          # @param [String] stage Name of the stage.
          # @return [String] JSON represention of the requested stage.
          # Get the details of the specified stage within the organization.
          # Returns every defined version for the given stage.
          app.get '/:stage' do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # There may be multiple versions of the same stage, so we need to
            # find every instance of the given stage, convert each Stage to a
            # hash & sanitize it
            stages = org.stages.where(name: params[:stage]).map do |stage|
              stage_hash = sanitize_stage(stage.serializable_hash)

              # Santize each action in this stage
              actions = stage.actions.map do |action|
                sanitize_action(action.serializable_hash)
              end
              stage_hash['actions'] = actions

              stage_hash
            end

            halt_with_json_response(404, INVALID_STAGE, 'stage does not exist') \
              if stages.empty?

            return stages.to_json
          end

          # @method get_organizations_organization_stages_stage_version
          # @param [String] name Name of the organization.
          # @param [String] stage Name of the stage.
          # @param [String] version Version of the stage.
          # @return [String] JSON represention of the requested stage.
          # Get the details of the specified stage within the organization.
          # Returns the specified version of the given stage.
          app.get '/:stage/:version' do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            stage = org.stages.find_by(name: params[:stage], version: params[:version])
            halt_with_json_response(404, INVALID_STAGE, 'stage does not exist') \
              if stage.nil?

            # Sanitize the stage
            stage_hash = sanitize_stage(stage.serializable_hash)

            # Santize each action in this stage
            actions = stage.actions.map do |action|
              sanitize_action(action.serializable_hash)
            end
            stage_hash['actions'] = actions

            return stage_hash.to_json
          end

          app.helpers do
            register Helpers
          end
        end

        # Helpers for Stages
        module Helpers
          # Create the serialized actions
          #
          # For each definition in the payload, inspect it and create the
          # appropriate object for that action; that class is then serialized
          # into JSON and stored in the Action in the database, and can then
          # be unserialized back in to the desired object when it's needed
          # without the database having to be aware of every single
          # permutation of possible actions and arguments to them.
          def create_actions(stage_actions)
            sequence = 1
            stage_actions.map do |stage_action|
              action = Action.new
              action.sequence = sequence

              # Discover the base class for the action
              action_object = if stage_action.key? 'command'
                                Cyclid.logger.debug "command action at sequence #{sequence}"
                                # XXX Create the appropriate Command object
                              elsif stage_action.key? 'plugin'
                                Cyclid.logger.debug "plugin action at sequence #{sequence}"
                                # XXX Create the appropriate Plugin object
                              else
                                Cyclid.logger.debug \
                                  "unknown action type at sequence #{sequence}: #{stage_action}"
                              end

              # Serialize the object into the Action and store it in the database.
              action.action = Oj.dump(action_object)
              action.save!

              sequence += 1

              action
            end
          end
        end
      end
    end
  end
end
