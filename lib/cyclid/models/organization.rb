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
    # Model for Organizations
    class Organization < ActiveRecord::Base
      Cyclid.logger.debug('In the Organization model')

      class << self
        # Return the collection of Organizations as an array of Hashes (instead
        # of Organization objects)
        def all_as_hash
          all.to_a.map(&:serializable_hash)
        end
      end

      validates :name, presence: true
      validates :owner_email, presence: true

      validates :rsa_private_key, presence: true
      validates :rsa_public_key, presence: true
      validates :salt, presence: true

      validates_uniqueness_of :name

      has_and_belongs_to_many :users,
                              after_add: :add_user_org_perm,
                              after_remove: :remove_user_org_perm

      has_many :userpermissions
      has_many :stages
      has_many :job_records
      has_many :plugin_configs

      # Ensure that a set of Userpermissions exist when a User is added to
      # this Organization
      def add_user_org_perm(user)
        Cyclid.logger.debug "Creating org. perm. for #{user.username}"
        user.userpermissions << Userpermission.new(organization: self)
      end

      # Remove Userpermissions when a User is removed from this Organization
      def remove_user_org_perm(user)
        Cyclid.logger.debug "Destroying org. perm. for #{user.username}"
        user.userpermissions.delete(Userpermission.find_by(organization: self))
      end
    end
  end
end
