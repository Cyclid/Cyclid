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
      # Base class for Transport plugins
      class Transport < Base
        def initialize(args = {})
        end

        # Return the 'human' name for the plugin type
        def self.human_name
          'transport'
        end

        # If possible, export each of the variables in env as a shell
        # environment variables. The default is simply to remember the
        # environment variables, which will be exported each time when a
        # command is run.
        def export_env(env = {})
          @env = env
        end

        # Run a command on the remote host.
        def exec(_cmd, _path = nil)
          false
        end

        # Disconnect the transport
        def close
        end
      end
    end
  end
end

require_rel 'transport/*.rb'
