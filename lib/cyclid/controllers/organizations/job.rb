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

          app.get do
          end

          app.post do
            authorized_for!(params[:name], Operations::WRITE)

            payload = parse_request_body
            Cyclid.logger.debug payload

            halt_with_json_response(400, INVALID_JOB, 'invalid job definition') \
              unless payload.key? 'sequence'

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            begin
              job = ::Cyclid::API::Job::JobView.new(payload, org)
              Cyclid.logger.debug job.to_hash

              job_id = Cyclid.dispatcher.dispatch(job)
            rescue StandardError => ex
              Cyclid.logger.debug ex
            end

            return {job_id: job_id}.to_json
          end
        end
      end
    end
  end
end
