require 'net/http'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Container for the Sinatra related controllers modules
      module ApiExtension
        # Wrapper for a static method to push a status update to Github
        module GithubStatus
          # Call the Github statuses API to update the status
          def self.set_status(statuses, auth_token, state, description)
            # Update the PR status

            statuses_url = URI(statuses)
            status = { state: state,
                       target_url: 'http://cyclid.io',
                       description: description,
                       context: 'continuous-integration/cyclid' }

            # Post the status to the statuses endpoint
            request = Net::HTTP::Post.new(statuses_url)
            request.content_type = 'application/json'
            request.add_field 'Authorization', "token #{auth_token}" \
              unless auth_token.nil?
            request.body = status.to_json

            http = Net::HTTP.new(statuses_url.hostname, statuses_url.port)
            http.use_ssl = (statuses_url.scheme == 'https')
            response = http.request(request)

            case response
            when Net::HTTPSuccess, Net::HTTPRedirection
              Cyclid.logger.info "updated PR status to #{state}"
            when Net::HTTPNotFound
              Cyclid.logger.error 'update PR status failed; possibly an auth failure'
              raise
            else
              Cyclid.logger.error "update PR status failed: #{response}"
              raise
            end
          rescue StandardError => ex
            Cyclid.logger.error "couldn't set status for PR: #{ex}"
            raise
          end
        end
      end
    end
  end
end
