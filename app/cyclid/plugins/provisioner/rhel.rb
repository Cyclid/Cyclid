# frozen_string_literal: true
# Copyright 2017, 2016 Liqwyd Ltd.
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

require_relative 'redhat/helpers'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # RHEL provisioner
      class RHEL < Provisioner
        def initialize
          @quiet = true
        end

        # Prepare a RHEL based build host
        def prepare(transport, buildhost, env = {})
          release = buildhost[:release].to_i

          Cyclid.logger.debug 'is RHEL'
          if release >= 6
            Cyclid.logger.debug 'is >= 6'
            prepare_redhat(transport, env)
          else
            Cyclid.logger.debug 'is < 5'
            prepare_redhat_5(transport, env)
          end
        end

        # Plugin metadata
        def self.metadata
          super.merge!(version: Cyclid::Api::VERSION,
                       license: 'Apache-2.0',
                       author: 'Liqwyd Ltd.',
                       homepage: 'http://docs.cyclid.io')
        end

        # Register this plugin
        register_plugin 'rhel'

        include Helpers::Redhat
      end
    end
  end
end
