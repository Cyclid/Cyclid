# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Intelligent buffer which can be passed to plugins which need to collate
    # output data from different commands during a job
    class LogBuffer
      def initialize(websocket)
        @websocket = websocket
      end

      def write(data)
        # XXX Append to log
        # XXX Write to web socket
        Cyclid.logger.debug data
      end
    end
  end
end
