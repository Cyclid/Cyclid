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
    # Model for Stages
    class Stage < ActiveRecord::Base
      Cyclid.logger.debug('In the Stage model')

      class << self
        # Return the collection of Stages as an array of Hashes (instead
        # of Stage objects)
        def all_as_hash
          all.to_a.map(&:serializable_hash)
        end
      end

      validates :name, presence: true
      validates :version, presence: true

      validates_uniqueness_of :name, scope: :version
      validates_format_of :version, with: /\A\d+.\d+.\d+.?\d*\z/

      belongs_to :organization
      has_many :steps
    end
  end
end
