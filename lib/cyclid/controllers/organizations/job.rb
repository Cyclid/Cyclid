# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for Organization Jobs
      module Jobs
        # Sinatra callback
        def self.registered(app)
          include Errors::HTTPErrors
          include Constants::JobStatus

          # @macro [attach] sinatra.post
          #   @overload post "$1"
          # @method post_organizations_organization_jobs
          # Create and run a job.
          app.post do
            authorized_for!(params[:name], Operations::WRITE)

            payload = parse_request_body
            Cyclid.logger.debug payload

            halt_with_json_response(400, INVALID_JOB, 'invalid job definition') \
              unless payload.key? 'sequence' and \
                     payload.key? 'environment'

            begin
              job_data = job_from_definition(payload)
            rescue StandardError => ex
              halt_with_json_response(500, INVALID_JOB, 'job failed')
            end

            return job_data
          end

          # @macro [attach] sinatra.get
          #   @overload get "$1"
          # @method get_organizations_organization_job
          # @return [String] JSON represention of the job record for the job ID.
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

          # @method get_organizations_organization_job_status
          # @return [String] JSON represention of the job status for the job ID.
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

          # @method get_organizations_organization_job_log
          # @return [String] JSON represention of the job log for the job ID.
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
