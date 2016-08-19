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

require 'sinatra-health-check'

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    module Health
      # Helper methods to isolate the plugins from the implementation details
      # of the healthcheck framework
      module Helpers
        # Health statuses
        STATUSES = {
          ok: SinatraHealthCheck::Status::SEVERITIES[:ok],
          warning: SinatraHealthCheck::Status::SEVERITIES[:warning],
          error: SinatraHealthCheck::Status::SEVERITIES[:error]
        }.freeze

        # Produce a SinatraHealthCheck object from the given status & message
        def health_status(status, message)
          SinatraHealthCheck::Status.new(status, message)
        end
      end
    end
  end
end
