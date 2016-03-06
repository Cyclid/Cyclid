# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Container for the Sinatra related controllers modules
      module ApiExtension
        # Github plugin method callbacks
        module GithubMethods
          include Methods

          def post(data, headers)
            Cyclid.logger.debug "in GithubMethods::post: #{headers}"

            return_failure(400, 'no event specified') \
              unless headers.include? 'X-Github-Event'

            return_failure(400, 'no delivery ID specified') \
              unless headers.include? 'X-Github-Delivery'

            event = headers['X-Github-Event']
            delivery = headers['X-Github-Delivery']
            signature = headers['X-Hub-Signature'] || nil

            Cyclid.logger.debug "Github: event is #{event}"

            if event == 'ping'
              result = gh_ping(data)
            elsif event == 'pull_request'
              result = gh_pull_request(data)
            else
              return_failure(400, "event type '#{event}' is not supported")
            end

            return result
          end

          # Handle a Ping event
          def gh_ping(data)
            Cyclid.logger.debug "hook=#{data['hook']} hook_id=#{data['hook_id']}"
            Cyclid.logger.info "your zen for the day is: #{data['zen']}"

            # 200 OK response with an empty body
            return true
          end

          # Handle Pull Request event
          def gh_pull_request(data)
            action = data['action'] || nil
            number = data['number'] || nil
            pr = data['pull_request'] || nil

            Cyclid.logger.debug "action=#{action}"
            return true unless action == 'opened' or action == 'reopened' or action == 'synchronize'

            # Get the list of files in the root of the repository in the
            # Pull Request branch
            pr_sha = pr['merge_commit_sha'] || nil
            Cyclid.logger.debug "SHA=#{pr_sha}"
            return_failure(400, 'no SHA') unless pr_sha

            url = URI(pr['head']['repo']['url'])
            url.user = '9fdeb8455415c9c9d1a91a73410a7bf91b5b63c2'
            pr_url = "#{url}/git/trees/#{pr_sha}"

            begin
              Cyclid.logger.debug "Getting root for #{pr_url}"
              response = Net::HTTP.get_response(URI(pr_url))
              Cyclid.logger.debug response.inspect
              raise "couldn't get repository root" unless response.code == '200'

              root = Oj.load response.body
            rescue StandardError => ex
              Cyclid.logger.error "failed to retrieve Pull Request root: #{ex}"
              raise
            end

            tree = root['tree']
            Cyclid.logger.debug "tree=#{tree}"

            # See if a .cyclid.yml or .cyclid.json file exists in the project
            # root
            job_url = nil
            tree.each do |file|
              if file['path'] =~ /\A\.cyclid\.(json|yml)\z/
                job_url = file['url']
                break
              end
            end

            Cyclid.logger.debug "job_url=#{job_url}"
            return_failure(400, 'not a Cyclid repository') unless job_url

            # Pull down the job file
            begin
              Cyclid.logger.info "Retrieving PR job from #{job_url}"
              response = Net::HTTP.get_response(URI(job_url))
              raise "couldn't get Cyclid job" unless response.code == '200'

              job_blob = Oj.load response.body
              job_json = Oj.load(Base64.decode64(job_blob['content']))
            rescue StandardError => ex
              Cyclid.logger.error "failed to retrieve Github Pull Request job: #{ex}"
              raise
            end

            Cyclid.logger.debug "job_json=#{job_json}"

            # XXX Leaky abstractions a-go-go!
            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            # Create a new JobRecord
            job_record = JobRecord.new
            job_record.started = Time.now.to_s
            job_record.status = Constants::JobStatus::NEW
            job_record.save!

            org.job_records << job_record
            #current_user.job_records << job_record

            begin
              job = ::Cyclid::API::Job::JobView.new(job_json, org)
              Cyclid.logger.debug job.to_hash

              job_id = Cyclid.dispatcher.dispatch(job, job_record)
            rescue StandardError => ex
              Cyclid.logger.error "Github: job failed: #{ex}"

              # We couldn't dispatch the job; record the failure
              job_record.status = Constants::JobStatus::FAILED
              job_record.ended = Time.now.to_s
              job_record.save!

              return_failure(500, 'job failed')
            end

            return { job_id: job_id }.to_json
          end
        end
      end

      # API extension for Github hooks 
      class Github < Api
        def self.controller
          return ApiExtension::Controller.new(ApiExtension::GithubMethods)
        end

        # Register this plugin
        register_plugin 'github'
      end
    end
  end
end
