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

            job_record = org.job_records.find(params[:id])
            halt_with_json_response(404, INVALID_JOB, 'job does not exist') \
              if job_record.nil?

            # XXX The "job" itself is a serialised internal representation and
            # probably not very useful to the user, so we might want to process
            # it into something more helpful here.
            return job_record.to_json
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
