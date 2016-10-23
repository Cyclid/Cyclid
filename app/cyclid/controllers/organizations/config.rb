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

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for Organization specific configuration
      # @api REST
      module Configs
        # rubocop:disable Metrics/LineLength
        # @!group Organizations

        # @!method get_organizations_organization_configs_type_plugin
        # @overload GET /organizations/:organization/configs/:type/:plugin
        # @macro rest
        # @param [String] organization Name of the organization.
        # @param [String] type The plugin type E.g. 'api' for an API plugin, 'source' for a
        #   Source plugin etc.
        # @param [String] plugin Name of the plugin.
        # Get the current configuration for the given plugin.
        # @return The plugin configuration for the given plugin.
        # @return [404] The organization or plugin does not exist.
        # @example Get the 'example' plugin configuration from the 'example' organization
        #   GET /organizations/example/configs/type/example => {"id":1,
        #                                                       "plugin":"example",
        #                                                       "version":"1.0.0",
        #                                                       "config":{<plugin specific object>},
        #                                                       "organization_id":2,
        #                                                       "schema":[<plugin configuration schema>]}

        # @!method put_organizations_organization_configs_type_plugin
        # @overload PUT /organizations/:organization/configs/:type/:plugin
        # @macro rest
        # @param [String] organization Name of the organization.
        # @param [String] type The plugin type E.g. 'api' for an API plugin, 'source' for a
        #   Source plugin etc.
        # @param [String] plugin Name of the plugin.
        # Update the plugin configuration
        # @return [200] The plugin configuration was updated.
        # @return [404] The organization or plugin does not exist.

        # @!endgroup
        # rubocop:enable Metrics/LineLength

        # Sinatra callback
        # @private
        def self.registered(app)
          include Errors::HTTPErrors
          include Constants::JobStatus

          # Return a list of plugins which have configs
          app.get do
            authorized_for!(params[:name], Operations::READ)

            configs = []
            Cyclid.plugins.all.each do |plugin|
              configs << {type: plugin.human_name, name: plugin.name } \
                if plugin.has_config?
            end

            return configs.to_json
          end

          # Get the current configuration for the given plugin.
          app.get '/:type/:plugin' do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            Cyclid.logger.debug "type=#{params[:type]} plugin=#{params[:plugin]}"

            # Find the plugin
            plugin = Cyclid.plugins.find(params[:plugin], params[:type])
            halt_with_json_response(404, INVALID_PLUGIN, 'plugin does not exist') \
              if plugin.nil?

            # Ask the plugin for the current config for this organization. This
            # will include the config schema under the 'schema' attribute.
            begin
              config = plugin.get_config(org)

              halt_with_json_response(404, INVALID_PLUGIN_CONFIG, 'failed to get plugin config') \
                if config.nil?
            rescue StandardError => ex
              halt_with_json_response(404, \
                                      INVALID_PLUGIN_CONFIG, \
                                      "failed to get plugin config: #{ex}") \
                if config.nil?
            end

            return config.to_json
          end

          # Update the plugin configuration
          app.put '/:type/:plugin' do
            authorized_for!(params[:name], Operations::ADMIN)

            payload = parse_request_body
            Cyclid.logger.debug payload

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # Find the plugin
            plugin = Cyclid.plugins.find(params[:plugin], params[:type])
            halt_with_json_response(404, INVALID_PLUGIN, 'plugin does not exist') \
              if plugin.nil?

            # Ask the plugin for the current config for this organization. This
            # will include the config schema under the 'schema' attribute.
            begin
              plugin.set_config(payload, org)
            rescue StandardError => ex
              halt_with_json_response(404, \
                                      INVALID_PLUGIN_CONFIG, \
                                      "failed to set plugin config: #{ex}") \
            end
          end
        end
      end
    end
  end
end
