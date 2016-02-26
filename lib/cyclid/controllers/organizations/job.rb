# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for Organization Jobs
      module Jobs
        def self.registered(app)
          include Errors::HTTPErrors
          include Constants::JobStatus

          app.post do
            authorized_for!(params[:name], Operations::WRITE)

            payload = parse_request_body
            Cyclid.logger.debug payload

            halt_with_json_response(400, INVALID_JOB, 'invalid job definition') \
              unless payload.key? 'sequence' and \
                     payload.key? 'environment'

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # Create a new JobRecord
            job_record = JobRecord.new
            job_record.started = Time.now.to_s
            job_record.status = NEW
            job_record.save!

            org.job_records << job_record
            current_user.job_records << job_record

            begin
              job = ::Cyclid::API::Job::JobView.new(payload, org)
              Cyclid.logger.debug job.to_hash

              job_id = Cyclid.dispatcher.dispatch(job, job_record)
            rescue StandardError => ex
              Cyclid.logger.error "job failed: #{ex}"

              # We couldn't dispatch the job; record the failure
              job_record.status = FAILED
              job_record.ended = Time.now.to_s
              job_record.save!

              halt_with_json_response(500, INVALID_JOB, 'job failed')
            end

            return {job_id: job_id}.to_json
          end

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

        end
      end
    end
  end
end
