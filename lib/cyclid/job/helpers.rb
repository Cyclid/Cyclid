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
    # Module for Cyclid Job related classes
    module Job
      # Useful methods for dealing with Jobs
      module Helpers
        # Create & dispatch a Job from the job definition
        def job_from_definition(definition, callback = nil, context = {})
          # This function will only ever be called from a Sinatra context
          org = Organization.find_by(name: params[:name])
          halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
            if org.nil?

          # Create a new JobRecord
          job_record = JobRecord.new
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

            # We couldn't dispatch the job; record the failure
            job_record.status = Constants::JobStatus::FAILED
            job_record.ended = Time.now.to_s
            job_record.save!

            raise
          end

          return job_id
        end
      end
    end
  end
end
