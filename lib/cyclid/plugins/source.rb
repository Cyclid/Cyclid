# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Base class for Source plugins
      class Source < Base
        # Return the 'human' name for the plugin type
        def self.human_name
          'source'
        end

        # Process the source to produce a copy of the remote code in a
        # directory in the working directory
        def checkout(_transport, _ctx, _source = {})
          false
        end
      end
    end
  end
end

require_rel 'source/*.rb'
