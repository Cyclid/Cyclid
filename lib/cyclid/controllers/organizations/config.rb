# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for Organization specific configuration
      module Configs
        # Sinatra callback
        def self.registered(app)
          include Errors::HTTPErrors
          include Constants::JobStatus

          # @macro [attach] sinatra.get
          #   @overload get "$1"
          # @method get_organizations_organization_config_plugin
          # @return [String] JSON represention of the plugin configuration for the given plugin.
          # Get the current configuration for the given plugin.
          app.get '/:plugin' do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # Find the plugin
            # XXX How do we deal with plugins with the same name but different types?
            # XXX Just hardwire this to be Api plugins for now
            plugin = Cyclid.plugins.find(params[:plugin], Cyclid::API::Plugins::Api)
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

          app.put '/:plugin' do
            authorized_for!(params[:name], Operations::ADMIN)

            payload = parse_request_body
            Cyclid.logger.debug payload

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # Find the plugin
            # XXX How do we deal with plugins with the same name but different types?
            # XXX Just hardwire this to be Api plugins for now
            plugin = Cyclid.plugins.find(params[:plugin], Cyclid::API::Plugins::Api)
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
