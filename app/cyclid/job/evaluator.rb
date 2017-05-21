# frozen_string_literal: true
# Copyright 2017 Liqwyd Ltd.
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
    # Module for Cyclid Job related classes
    module Job
      # Evaluator exception class
      class EvalException < RuntimeError
      end

      # Evalute an expression for "only_if", "not_if" & "fail_if"
      class Evaluator
        class << self
          def only_if(statement, vars)
            evaluate(statement, vars)
          end
          alias fail_if only_if

          def not_if(statement, vars)
            not evaluate(statement, vars) # rubocop:disable Style/Not
          end

          private

          def compare(lvalue, operator, rvalue)
            case operator
            # Loose (case insensitive) comparision
            when '=='
              lvalue.downcase == rvalue.downcase # rubocop:disable Performance/Casecmp
            # Case sensitive/value comparision
            when '===', 'eq'
              lvalue == rvalue
            # Not-equal
            when '!=', 'ne'
              lvalue != rvalue
            # Less than
            when '<', 'lt'
              lvalue.to_f < rvalue.to_f
            # Greater than
            when '>', 'gt'
              lvalue.to_f > rvalue.to_f
            # Less than or equal
            when '<=', 'le'
              lvalue.to_f <= rvalue.to_f
            # Greater than or equal
            when '>=', 'ge'
              lvalue.to_f >= rvalue.to_f
            # Not an operator we know
            else
              raise EvalException, "unknown operator: #{operator}"
            end
          end

          def evaluate(statement, vars)
            # Replace single % characters with escaped versions and interpolate
            expr = statement.gsub(/%([^{])/, '%%\1') ** vars

            # Evaluate for both string comparisons:
            #
            # 'string1' == 'string2'
            #
            # and numbers:
            #
            # 1 < 2
            #
            # Numbers can be integers, floats or percentages
            #
            # Only the ==, != and === operators are recognised for strings. All
            # operators, including == & != are valid for Numbers: === is not a valid
            # operator for numbers.

            # rubocop:disable Metrics/LineLength
            case expr
            when /\A'(.*)' (==|!=|===) '(.*)'\Z/,
                 /\A([0-9]*|[0-9]*\.[0-9]*)%? (==|eq|!=|ne|<|lt|>|gt|<=|le|>=|ge) ([0-9]*|[0-9]*\.[0-9]*)%?\Z/
              compare(Regexp.last_match[1],
                      Regexp.last_match[2],
                      Regexp.last_match[3])
            else
              raise EvalException, "unable to evaluate #{expr}"
            end
            # rubocop:enable Metrics/LineLength
          end
        end
      end
    end
  end
end
