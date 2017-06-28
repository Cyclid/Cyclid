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

require 'cyclid/linter'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Job related classes
    module Job
      # Useful methods for dealing with Jobs
      module Helpers
        include Cyclid::API::Exceptions

        # Create & dispatch a Job from the job definition
        def job_from_definition(definition, callback = nil, context = {})
          # Job definition is a hash (converted from JSON or YAML)
          definition.symbolize_keys!

          # This function will only ever be called from a Sinatra context
          org = Organization.find_by(name: params[:name])
          raise NotFoundError, 'organization does not exist' \
            if org.nil?

          # Lint the job and reject if there are errors
          verifier = Cyclid::Linter::Verifier.new
          verifier.verify(definition)

          raise InvalidObjectError, 'job definition has errors' \
            unless verifier.status.errors.zero?

          # Create a new JobRecord
          job_record = JobRecord.new
          job_record.job_name = definition[:name]
          job_record.job_version = definition[:version] || '1.0.0'
          job_record.started = Time.now.to_s
          job_record.status = Constants::JobStatus::NEW
          job_record.save!

          org.job_records << job_record

          # The user may, or may not, be set: if the job has come via. the :organization/jobs
          # endpoint it'll be set (as that's authenticated), if it's come from an API extension the
          # user mat not be set (as it may be unauthenticated, or not using the same authentication
          # as Cyclid)
          user = current_user
          current_user.job_records << job_record if user

          begin
            job = ::Cyclid::API::Job::JobView.new(definition, context, org)
            Cyclid.logger.debug job.to_hash

            job_id = Cyclid.dispatcher.dispatch(job, job_record, callback)
          rescue StandardError => ex
            Cyclid.logger.error "job dispatch failed: #{ex}"
            Cyclid.logger.debug ex.backtrace.join "\n"

            # We couldn't dispatch the job; record the failure
            job_record.status = Constants::JobStatus::FAILED
            job_record.ended = Time.now.to_s
            job_record.save!

            # Re-raise something useful
            raise InternalError, "job dispatch failed: #{ex}"
          end

          return job_id
        end
      end
    end
  end
end
