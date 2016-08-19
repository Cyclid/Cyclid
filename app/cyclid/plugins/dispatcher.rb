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
      # Base class for Dispatcher
      class Dispatcher < Base
        # Return the 'human' name for the plugin type
        def self.human_name
          'dispatcher'
        end

        # Dispatch a job to a worker and return some opaque data that can be
        # used to identify that job (E.g. an ID, UUID etc.)
        def dispatch(job, record, callback = nil)
        end
      end

      # A Runner may be running locally (within the API application context)
      # or remotely. A job runner needs to send updates about the job status
      # but obviously, a remote runner can't just update the JobRecord
      # directly: they may put a message on a queue, which a job at the API
      # application would consume and update the JobRecord.
      #
      # A Notifier provides an abstract method to update the JobRecord
      # status and can also proxy LogBuffer writes.
      #
      module Notifier
        # Base class for Notifiers
        class Base
          def initialize(job_id, callback_object)
          end

          # Update the JobRecord status
          def status=(status)
          end

          # Update the JobRecord ended field
          def ended=(time)
          end

          # Notify any callbacks that the job has completed
          def completion(success)
          end

          # Proxy data to the log buffer
          def write(data)
          end
        end

        # Plugins may create a Callback instance that contains callbacks which
        # are called by the Notifier when something happens; the Plugin can
        # then take whatever action they need (E.g. updating an external
        # status)
        class Callback
          # Called when the job completes
          def completion(_job_id, _status)
          end

          # Called whenever the job status changes
          def status_changed(_job_id, _status)
          end

          # Called whenever any data is written to the job record log
          def log_write(_job_id, _data)
          end
        end
      end
    end
  end
end

require_rel 'dispatcher/*.rb'
