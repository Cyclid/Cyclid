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
    # Module for Cyclid Plugins
    module Plugins
      # "Log" plugin; will always succeed. Simply emits a message to the log.
      class Log < Action
        def initialize(args = {})
          args.symbolize_keys!

          # There must be a message to log.
          raise 'a log action requires a message' unless args.include? :message

          @message = args[:message]
        end

        # Write the log message, with the context data interpolated
        def perform(log)
          log.write("#{@message ** @ctx}\n")
          true
        end

        # Register this plugin
        register_plugin 'log'
      end
    end
  end
end
