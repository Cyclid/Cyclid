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
      # Fedora provisioner
      class Fedora < Provisioner
        def initialize
          @quiet = true
        end

        # Prepare a Fedora based build host
        def prepare(transport, buildhost, env = {})
          release = buildhost[:release].to_i

          Cyclid.logger.debug 'is Fedora'
          if release >= 22
            Cyclid.logger.debug 'is >= 22'
            prepare_fedora_dnf(transport, env)
          else
            Cyclid.logger.debug 'is < 22'
            prepare_fedora_yum(transport, env)
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
        register_plugin 'fedora'

        include Helpers::Redhat
      end
    end
  end
end
