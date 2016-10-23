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

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Simple in-memory FIFO; inspired by StringIO but reads & writes maintain
    # their own position. It's unlike a file enough to not be derived from IO.
    class StringFIFO
      def initialize
        @buffer = String.new
        @write_pos = 0
        @read_pos = 0
      end

      # Append data to the buffer & update the write position
      def write(data)
        @buffer += data
        @write_pos += data.length
      end

      # Read data from the buffer. If length is given, read at most length
      # characters from the buffer or whatever is available, whichever is
      # smaller.
      #
      # Completely non-blocking; if no data is available, returns an empty
      # string.
      def read(length = nil)
        len = if length
                [length, @write_pos].min
              else
                @write_pos
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
      def initialize(job_record = nil, websocket = nil)
        @job_record = job_record
        @websocket = websocket
        @buffer = StringFIFO.new
      end

      # Append data to the log and send it on to any configured consumers
      def write(data)
        # Append the new data to log
        @buffer.write data

        # Update the Job Record, if there is one
        if @job_record
          # XXX: This will destroy the database. Find a better method.
          @job_record.log = @buffer.string
          @job_record.save!
        end

        # Write to web socket
        @websocket&.write data
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
