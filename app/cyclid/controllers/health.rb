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
    # Controller for all Health related API endpoints
    # @api REST
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

      # @!group Health

      # @!method get_health_status
      # @overload GET /health/status
      # @macro rest
      # Return either 200 (healthy) or 503 (unhealthy) based on the status of
      # the healthchecks. This is intended to be used by things like load
      # balancers and active monitors.
      # @return [200] Application is healthy.
      # @return [503] Application is unhealthy.
      get '/health/status' do
        @checker.healthy? ? 200 : 503
      end

      # @!method get_health_info
      # @overload GET /health/info
      # @macro rest
      # Return verbose information on the status of the individual checks;
      # note that this method always returns 200 with a message body, so it is
      # not suitable for general health checks unless the caller intends to
      # parse the message body for the health status.
      # @return JSON description of the individual health check statuses.
      get '/health/info' do
        @checker.status.to_json
      end

      # @!endgroup
    end

    # Register this controller
    Cyclid.controllers << HealthController

    # Healthchecks
    module Health
      # Internal database connection health check
      module Database
        # Check that ActiveRecord can connect to the database
        def self.status
          connected = begin
                        ActiveRecord::Base.connection_pool.with_connection(&:active?)
                      rescue
                        false
                      end

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
