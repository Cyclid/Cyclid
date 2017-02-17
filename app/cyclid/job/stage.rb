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

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Job related classes
    module Job
      # Non-AR model for Stages. Using a wrapper allows us to create an ad-hoc
      # stage (I.e. one that is not stored in the database) or load a stage
      # from the database and merge in over-rides without risking modifying
      # the database object.
      class StageView
        attr_reader :name, :version, :steps
        attr_accessor :on_success, :on_failure, :only_if, :not_if

        def initialize(arg)
          if arg.is_a? Cyclid::API::Stage
            @name = arg.name
            @version = arg.version
            @steps = arg.steps.map(&:serializable_hash)
          elsif arg.is_a? Hash
            arg.symbolize_keys!

            raise ArgumentError, 'name is required' unless arg.key? :name

            @name = arg[:name]
            @version = arg.fetch(:version, '1.0.0')

            # Create & serialize Actions for each step
            sequence = 1
            @steps = arg[:steps].map do |step|
              Cyclid.logger.debug "ad-hoc step=#{step}"

              action_name = step['action']
              plugin = Cyclid.plugins.find(action_name, Cyclid::API::Plugins::Action)

              step_action = plugin.new(step)
              raise ArgumentError if step_action.nil?

              # Serialize the object into the Step and store it in the database.
              action = Oj.dump(step_action)

              step_definition = { sequence: sequence, action: action }
              sequence += 1

              step_definition
            end
          end
        end
      end
    end
  end
end
