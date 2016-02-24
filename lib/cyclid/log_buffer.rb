# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Simple in-memory FIFO; inspired by StringIO but reads & writes maintain
    # their own position. It's unlike a file enough to not be derived from IO.
    class StringFIFO
      def initialize
        @buffer = ''
        @write_pos = 0
        @read_pos = 0
      end

      # Append data to the buffer & update the write position
      def write(data)
        @buffer << data
        @write_pos += data.length
      end

      # Read data from the buffer. If length is given, read at most length
      # characters from the buffer or whatever is available, whichever is
      # smaller.
      #
      # Completely non-blocking; if no data is available, returns an empty
      # string.
      def read(length = nil)
        if length
          len = [length, @write_pos].min
        else
          len = @write_pos
        end
        start = @read_pos
        @read_pos += len

        @buffer[start, len]
      end

      # Return the entire contents of the buffer
      def string
        @buffer
      end

      alias to_s string

      # Reset the buffer, read & write positions
      def clear
        @buffer = ''
        @write_pos = 0
        @read_pos = 0
      end
    end

    # Intelligent buffer which can be passed to plugins which need to collate
    # output data from different commands during a job
    class LogBuffer
      def initialize(websocket)
        @websocket = websocket
        @buffer = StringFIFO.new
      end

      # Append data to the log and send it on to any configured consumers
      def write(data)
        # Append the new data to log
        @buffer.write data

        # XXX Write to web socket
        # @websocket.write data

        Cyclid.logger.debug data
      end

      # Non-destructively read any new data from the buffer
      def read(length = nil)
        @buffer.read(length)
      end

      # Return a complete copy of the data from the buffer
      def log
        @buffer.string
      end
    end
  end
end
