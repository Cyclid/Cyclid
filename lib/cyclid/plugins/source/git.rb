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
        def checkout(transport, ctx, source = {})
          source.symbolize_keys!

          raise 'invalid git source definition' \
            unless source.key? :url

          url = URI(source[:url])

          # If the source includes an OAuth token, add it to the URL as the
          # username
          url.user = source[:token] if source.key? :token

          success = transport.exec "git clone #{url}"
          return false unless success

          # If a branch was given, check it out
          if source.key? :branch
            branch = source[:branch]

            match = url.path.match(/^.*\/(\w*)/)
            source_dir = "#{ctx[:workspace]}/#{match[1]}"

            success = transport.exec("git fetch origin #{branch}:#{branch}", source_dir)
            success = transport.exec("git checkout #{branch}", source_dir) \
              unless success == false
          end

          return success
        end

        # Register this plugin
        register_plugin 'git'
      end
    end
  end
end
