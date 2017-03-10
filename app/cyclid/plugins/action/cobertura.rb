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

require 'nokogiri'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Cobertura (& compatible) coverage reader plugin
      class Cobertura < Action
        def initialize(args = {})
          args.symbolize_keys!

          # There must be the path to the coverage report..
          raise 'a Cobertura action requires a path' unless args.include? :path

          @path = args[:path]
        end

        def perform(log)
          # Retrieve the Cobertura XML report
          report = StringIO.new
          @transport.download(report, @path ** @ctx)

          # Parse the report and extract the line & branch coverage.
          xml = Nokogiri.parse(report.string)
          coverage = xml.xpath('//coverage')
          line_rate = coverage.attr('line-rate').value.to_i
          branch_rate = coverage.attr('branch-rate').value.to_i

          # Coverage is given as a fraction, so convert it to a percentage.
          #
          # Cobertura can produce oddly specific coverage metrics, so round it
          # to only 2 decimal points...
          line_rate_pct = (line_rate * 100).round(2)
          branch_rate_pct = (branch_rate * 100).round(2)

          log.write "Cobertura coverage line rate is #{line_rate_pct}%, " \
                    "branch rate is #{branch_rate_pct}%\n"

          @ctx[:cobertura_line_rate] = "#{line_rate_pct}%"
          @ctx[:cobertura_branch_rate] = "#{branch_rate_pct}%"

          return [true, 0]
        rescue StandardError => ex
          log.write "Failed to read Cobertura coverage report: #{ex}"

          return [false, 0]
        end

        # Register this plugin
        register_plugin 'cobertura'
      end
    end
  end
end
