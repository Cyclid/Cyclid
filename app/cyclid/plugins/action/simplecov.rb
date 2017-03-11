# frozen_string_literal: true
# Copyright 2016, 2017 Liqwyd Ltd.
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
    # Module for Cyclid Plugins
    module Plugins
      # Simplecov coverage reader plugin
      class Simplecov < Action
        def initialize(args = {})
          args.symbolize_keys!

          # There must be the path to the coverage report..
          raise 'a simplecov action requires a path' unless args.include? :path

          @path = args[:path]
        end

        def perform(log)
          # Retrieve the Simplecov JSON report
          report = StringIO.new
          @transport.download(report, @path ** @ctx)

          # Parse the report and extract the total coverage percentage;
          # Simplecov can produce oddly specific coverage metrics, so round it
          # to only 2 decimal points...
          coverage = JSON.parse(report.string)
          covered_percent = coverage['metrics']['covered_percent'].round(2)

          log.write "Simplecov coverage is #{covered_percent}%\n"
          @ctx[:simplecov_coverage] = "#{covered_percent}%"

          return [true, 0]
        rescue StandardError => ex
          log.write "Failed to read Simplecov coverage report: #{ex}"

          return [false, 0]
        end

        # Register this plugin
        register_plugin 'simplecov'
      end
    end
  end
end
