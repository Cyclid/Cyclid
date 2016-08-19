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
    # Controller for all Health related API endpoints
    class HealthController < ControllerBase
      include Errors::HTTPErrors

      def initialize(_app)
        super
        @checker = SinatraHealthCheck::Checker.new(logger: Cyclid.logger,
                                                   timeout: 0)

        # Add internal health checks
        @checker.systems[:database] = Cyclid::API::Health::Database

        # Add each plugin, which can choose to provide a healthcheck by
        # implementing #status
        Cyclid.plugins.all.each do |plugin|
          name = "#{plugin.human_name}_#{plugin.name}".to_sym
          @checker.systems[name] = plugin
        end
      end

      # Return either 200 (healthy) or 503 (unhealthy) based on the status of
      # the healthchecks. This is intended to be used by things like load
      # balancers and active monitors.
      get '/health/status' do
        @checker.healthy? ? 200 : 503
      end

      # Return verbose information on the status of the individual checks;
      # note that this method always returns 200 with a message body, so it is
      # not suitable for general health checks unless the caller intends to
      # parse the message body for the health status.
      get '/health/info' do
        @checker.status.to_json
      end
    end

    # Register this controller
    Cyclid.controllers << HealthController

    # Healthchecks
    module Health
      module Database
        def self.status
          connected = ActiveRecord::Base.connection_pool.with_connection do |con|
            con.active?
          end rescue false

          if connected
            SinatraHealthCheck::Status.new(:ok, 'database connection is okay')
          else
            SinatraHealthCheck::Status.new(:error, 'database is not connected')
          end
        end
      end
    end
  end
end
