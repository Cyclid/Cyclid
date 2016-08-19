# frozen_string_literal: true
# Copyright 2016 Liqwyd Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for Organization Stages
      # @api REST
      module Stages
        # @!group Organizations

        # @!method get_organizations_organization_stages
        # @overload GET /organizations/:organization/stages
        # @macro rest
        # @param [String] organization Name of the organization.
        # Get all of the stages.
        # @return All the stages within the organization.
        # @return [404] The organization does not exist

        # @!method post_organizations_organization_stages(body)
        # @overload POST /organizations/:organization/stages
        # @macro rest
        # @param [String] organization Name of the organization.
        # Create a new stage.
        # @param [JSON] body New stage
        # @option body [String] name Name of the new stage
        # @option body [String] version (0.0.1) Version of the new stage
        # @option body [Array<Object>] steps List of steps for the stage
        # @return [400] The definition for the stage is invalid.
        # @return [404] The organization does not exist.
        # @return [409] A stage with the same name & version already exists.
        # @example Create a simple stage for 'example' organization
        #   POST /organizations/example/stages <= {"name": "example",
        #                                          "steps": [
        #                                            {
        #                                              "action": "command",
        #                                              "cmd": "bundle install"
        #                                            }
        #                                          ]}

        # @!method get_organizations_organization_stages_stage
        # @overload GET /organizations/:organization/stages/:stage
        # @macro rest
        # @param [String] organization Name of the organization.
        # @param [String] stage Name of the stage.
        # Get the details of the specified stage within the organization. Returns every defined
        # version for the given stage.
        # @return The requested stage.
        # @return [404] The organization or stage does not exist

        # @!method get_organizations_organization_stages_stage_version
        # @overload GET /organizations/:organization/stages/:stage/:version
        # @macro rest
        # @param [String] organization Name of the organization.
        # @param [String] stage Name of the stage.
        # @param [String] version Version of the stage.
        # Get the details of the specified stage within the organization. Returns the specified
        # version of the given stage.
        # @return The requested stage.
        # @return [404] The organization, stage or version of the stage does not exist

        # @!endgroup

        # Sinatra callback
        # @private
        def self.registered(app)
          include Errors::HTTPErrors

          # Get all of the stages.
          app.get do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # Convert each Stage to a hash & sanitize it
            stages = org.stages.all.map do |stage|
              stage_hash = sanitize_stage(stage.serializable_hash)

              # Santize each step in this stage
              steps = stage.steps.map do |step|
                sanitize_step(step.serializable_hash)
              end
              stage_hash['steps'] = steps

              stage_hash
            end

            return stages.to_json
          end

          # Create a new stage.
          app.post do
            authorized_for!(params[:name], Operations::ADMIN)

            payload = parse_request_body
            Cyclid.logger.debug payload

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            halt_with_json_response(400, INVALID_JSON, 'stage does not define any steps') \
              unless payload.key? 'steps'

            # Ensure that a stage with the same name & version doesn't already exist
            version = payload['version'] || '0.0.1'
            halt_with_json_response(409, \
                                    DUPLICATE, \
                                    'A stage with that name and version already exists') \
            if org.stages.exists?(name: payload['name'], version: version)

            begin
              stage = Stage.new

              stage.name = payload['name']
              stage.version = payload['version'] if payload.key? 'version'
              stage.organization = org

              # Create the steps & store their serialized form
              stage.steps << create_steps(payload['steps'])

              stage.save!
            rescue ActiveRecord::ActiveRecordError, \
                   ActiveRecord::UnknownAttributeError => ex

              Cyclid.logger.debug ex.message
              halt_with_json_response(400, INVALID_JSON, ex.message)
            end
          end

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

              # Santize each step in this stage
              steps = stage.steps.map do |step|
                sanitize_step(step.serializable_hash)
              end
              stage_hash['steps'] = steps

              stage_hash
            end

            halt_with_json_response(404, INVALID_STAGE, 'stage does not exist') \
              if stages.empty?

            return stages.to_json
          end

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

            # Santize each step in this stage
            steps = stage.steps.map do |step|
              sanitize_step(step.serializable_hash)
            end
            stage_hash['steps'] = steps

            return stage_hash.to_json
          end

          app.helpers do
            include Helpers
          end
        end

        # Helpers for Stages
        module Helpers
          include Errors::HTTPErrors

          # Create the serialized steps
          #
          # For each definition in the payload, inspect it and create the
          # appropriate object for that action; that class is then serialized
          # into JSON and stored in the Step in the database, and can then
          # be unserialized back in to the desired object when it's needed
          # without the database having to be aware of every single
          # permutation of possible actions and arguments to them.
          #
          # @private
          def create_steps(stage_steps)
            sequence = 1
            stage_steps.map do |stage_step|
              step = Step.new
              step.sequence = sequence

              begin
                action_name = stage_step['action']
                plugin = Cyclid.plugins.find(action_name, Cyclid::API::Plugins::Action)

                step_action = plugin.new(stage_step)
                raise if step_action.nil?
              rescue StandardError => ex
                # XXX Rescue an internal exception
                halt_with_json_response(404, INVALID_ACTION, ex.message)
              end

              # Serialize the object into the Step and store it in the database.
              step.action = Oj.dump(step_action)
              step.save!

              sequence += 1

              step
            end
          end
        end
      end
    end
  end
end
