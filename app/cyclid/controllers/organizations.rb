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
            key == 'organization_id' || key == 'id'
          end
        end

        # Clean up step data
        def sanitize_step(step)
          Cyclid.logger.debug step.inspect

          # Re-factor the step definition back into the original. The internal
          # representation carries a lot of extra metadata that users don't
          # need to worry about; the original definition is actually the
          # 'action' object inside of the step. The original 'action' key can
          # be reversed from the Action object name, without having to
          # unserialize the object
          #
          # Note that we use JSON and not Oj; if we try to use Oj it will
          # attempt to unserialise the object, which is not what we want.
          action = JSON.parse(step['action'])

          # Reverse the action name from the object name and remove the object
          # name
          action['action'] = action['^o'].split('::').last.downcase
          action.delete('^o')

          return action
        end

        # Remove sensitive data from the organization data
        def sanitize_organization(org)
          org.delete_if do |key, _value|
            key == 'rsa_private_key' || key == 'rsa_public_key' || key == 'salt'
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

          namespace '/jobs' do
            register Organizations::Jobs
          end

          namespace '/configs' do
            register Organizations::Configs
          end

          namespace '/plugins' do
            Cyclid.plugins.all(Cyclid::API::Plugins::Api).each do |plugin|
              Cyclid.logger.debug "Registering API extension plugin #{plugin.name}"

              # Create a namespace for this plugin and register it
              namespace "/#{plugin.name}" do
                ctrl = plugin.controller
                register ctrl
                helpers ctrl.plugin_methods
              end
            end
          end
        end
      end
    end
    Cyclid.controllers << OrganizationController
  end
end
