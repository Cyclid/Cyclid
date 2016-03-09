# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Git source plugin
      class Git < Source
        # Run commands via. the transport to check out a given Git remote
        # repository
        def checkout(transport, source = {})
          source.symbolize_keys!

          raise 'invalid git source definition' \
            unless source.key? :url

          url = URI(source[:url])

          # If the source includes an OAuth token, add it to the URL as the
          # username
          url.user = source[:token] if source.key? :token

          return transport.exec "git clone #{url}"
        end

        # Register this plugin
        register_plugin 'git'
      end
    end
  end
end
