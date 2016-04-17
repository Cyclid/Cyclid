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

require 'yaml'

module Cyclid
  module API
    # Cyclid API configuration
    class Config
      attr_reader :database, :log, :dispatcher, :builder

      def initialize(path)
        @config = YAML.load_file(path)

        @database = @config['database']
        @log = @config['log'] || File.join(%w(/ var log cyclid))
        @dispatcher = @config['dispatcher']
        @builder = @config['builder']
      rescue StandardError => ex
        abort "Failed to load configuration file #{path}: #{ex}"
      end
    end
  end
end
