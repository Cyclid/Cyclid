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

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for Organization Jobs
      # @api REST
      module Jobs
        # rubocop:disable Metrics/LineLength
        # @!group Organizations

        # @!method get_organizations_organization_jobs
        # @overload GET /organizations/:organization/jobs
        # @param [String] organization Name of the organization.
        # @param [Boolean] stats_only Do not return the job records; just the count
        # @param [Integer] limit Maxiumum number of records to return.
        # @param [Integer] offset Offset to start returning records.
        # @param [String] s_name Name of the job to search on.
        # @param [Integer] s_status Status to search on.
        # @param [String] s_from Date & time to search from.
        # @param [String] s_to Date & time to search to.
        # @macro rest
        # Get a list of jobs that have been run for the organization. Jobs can be
        # filtered using the s_name, s_status, s_from and s_to search parameters. If
        # s_from & s_to are given, only jobs which started between the two times will
        # be returned.
        # @return The list of job details.
        # @return [404] The organization does not exist.

        # @!method post_organizations_organization_jobs(body)
        # @overload POST /organizations/:organization/jobs
        # @macro rest
        # @param [String] organization Name of the organization.
        # Create and run a job. The job definition can be either a JSON or
        # YAML document.
        # @param [JSON] body Job definition
        # @option body [String] name Name of the job.
        # @option body [Object] environment Job runtime environment details. At a minimum this
        #   must include the operating system name & version to use.
        # @option body [Object] secrets ({}) Encrypted secret data for use by the job.
        # @option body [Array<Object>] stages ([]) Ad-hoc stage definitions which are local to this job.
        # @option body [Array<Object>] sequence ([]) List of stages to be run.
        # @return [200] The job was created and successfully queued.
        # @return [400] The job definition was invalid.
        # @return [404] The organization does not exist.
        # @example Create a simple job in the 'example' organization with no secrets or ad-hoc stages
        #   POST /organizations/example/jobs <= {"name": "example",
        #                                        "environment" : {
        #                                          "os" : "ubuntu_trusty"
        #                                         },
        #                                         "sequence": [
        #                                           {
        #                                             "stage": "example_stage"
        #                                           }
        #                                         ]}

        # @!method get_organizations_organization_job
        # @overload GET /organizations/:organization/jobs/:job
        # @param [String] organization Name of the organization.
        # @param [Integer] job Job ID.
        # @macro rest
        # Get the complete JobRecord for the given job ID.
        # @return The job record for the job ID.
        # @return [404] The organization or job record does not exist.

        # @!method get_organizations_organization_job_status
        # @overload GET /organizations/:organization/jobs/:job/status
        # @param [String] organization Name of the organization.
        # @param [Integer] job Job ID.
        # @macro rest
        # Get the current status of the given job ID.
        # @return The current job status for the job ID.
        # @return [404] The organization or job record does not exist.

        # @!method get_organizations_organization_job_log
        # @overload GET /organizations/:organization/jobs/:job/log
        # @param [String] organization Name of the organization.
        # @param [Integer] job Job ID.
        # @macro rest
        # Get the current complete log of the given job ID.
        # @return The job log for the job ID.
        # @return [404] The organization or job record does not exist.

        # @!endgroup
        # rubocop:enable Metrics/LineLength

        # Sinatra callback
        # @private
        def self.registered(app)
          include Errors::HTTPErrors
          include Constants::JobStatus

          # Return a list of jobs
          app.get do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # Get any search terms that we'll need to find the appropriate jobs
            search = {}
            search[:job_name] = URI.decode(params[:s_name]) if params[:s_name]
            search[:status] = params[:s_status] if params[:s_status]

            # search_from & search_to should be some parsable format
            if params[:s_from] and params[:s_to]
              from = Time.parse(params[:s_from])
              to = Time.parse(params[:s_to])

              # ActiveRecord understands a range
              search[:started] = from..to
            end

            Cyclid.logger.debug "search=#{search.inspect}"

            # Find the number of matching jobs
            count = if search.empty?
                      org.job_records.count
                    else
                      org.job_records
                      .where(search)
                      .count
                    end

            Cyclid.logger.debug "count=#{count}"

            stats_only = params[:stats_only] || false
            limit = params[:limit] || 100
            offset = params[:offset] || 0

            job_data = {'total' => count,
                        'offset' => offset,
                        'limit' => limit}

            if not stats_only
              # Get the available job records, but be terse with the
              # information returned; there is no need to return a full job log
              # with every job, for example.
              job_records = if search.empty?
                              org.job_records
                                .all
                                .select('id, job_name, job_version, started, ended, status')
                                .offset(offset)
                                .limit(limit)
                            else
                              org.job_records
                                .where(search)
                                .select('id, job_name, job_version, started, ended, status')
                                .offset(offset)
                                .limit(limit)
                            end

              job_data['records'] = job_records
            end

            return job_data.to_json
          end

          # Create and run a job.
          app.post do
            authorized_for!(params[:name], Operations::WRITE)

            payload = parse_request_body
            Cyclid.logger.debug payload

            halt_with_json_response(400, INVALID_JOB, 'invalid job definition') \
              unless payload.key? 'sequence' and \
                     payload.key? 'environment'

            begin
              job_id = job_from_definition(payload)
            rescue StandardError => ex
              halt_with_json_response(500, INVALID_JOB, "job failed: #{ex}")
            end

            return { job_id: job_id }.to_json
          end

          # Get the complete JobRecord for the given job ID.
          app.get '/:id' do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            begin
              job_record = org.job_records.find(params[:id])
              halt_with_json_response(404, INVALID_JOB, 'job does not exist') \
                if job_record.nil?
            rescue StandardError => ex
              halt_with_json_response(404, INVALID_JOB, 'job does not exist')
            end

            job = job_record.serializable_hash
            job[:job_id] = job.delete :id

            # XXX The "job" itself is a serialised internal representation and
            # probably not very useful to the user, so we might want to process
            # it into something more helpful here.
            return job.to_json
          end

          # Get the current status of the given job ID.
          app.get '/:id/status' do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            job_record = org.job_records.find(params[:id])
            halt_with_json_response(404, INVALID_JOB, 'job does not exist') \
              if job_record.nil?

            hash = {}
            hash[:job_id] = job_record.id
            hash[:status] = job_record.status

            return hash.to_json
          end

          # Get the current complete log of the given job ID.
          app.get '/:id/log' do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            job_record = org.job_records.find(params[:id])
            halt_with_json_response(404, INVALID_JOB, 'job does not exist') \
              if job_record.nil?

            hash = {}
            hash[:job_id] = job_record.id
            hash[:log] = job_record.log

            return hash.to_json
          end

          app.helpers do
            include Job::Helpers
          end
        end
      end
    end
  end
end
