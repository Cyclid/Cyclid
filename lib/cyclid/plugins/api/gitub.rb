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

            case event
            when 'pull_request'
              result = gh_pull_request(data)
            when 'ping'
              result = true
            when 'status'
              result = true
            else
              return_failure(400, "event type '#{event}' is not supported")
            end

            return result
          end

          # Handle Pull Request event
          def gh_pull_request(data)
            action = data['action'] || nil
            number = data['number'] || nil
            pr = data['pull_request'] || nil

            Cyclid.logger.debug "action=#{action}"
            return true unless action == 'opened' \
                        or action == 'reopened' \
                        or action == 'synchronize'

            # Get the list of files in the root of the repository in the
            # Pull Request branch
            pr_sha = pr['head']['sha'] || nil
            Cyclid.logger.debug "SHA=#{pr_sha}"
            return_failure(400, 'no SHA') unless pr_sha

            repo_url = URI(pr['head']['repo']['url'])

            # Set the PR to 'pending'
            GithubStatus.set_status(repo_url, pr_sha, 'pending', 'Waiting for build')

            # Get the Pull Request
            begin
              pr_url = URI("#{repo_url}/git/trees/#{pr_sha}")
              Cyclid.logger.debug "Getting root for #{pr_url}"

              request = Net::HTTP::Get.new(pr_url)
              request.add_field 'Authorization', 'token 9fdeb8455415c9c9d1a91a73410a7bf91b5b63c2'

              http = Net::HTTP.new(pr_url.hostname, pr_url.port)
              http.use_ssl = (pr_url.scheme == 'https')
              response = http.request(request)

              Cyclid.logger.debug response.inspect
              raise "couldn't get repository root" unless response.code == '200'

              root = Oj.load response.body
            rescue StandardError => ex
              Cyclid.logger.error "failed to retrieve Pull Request root: #{ex}"
              return_failure(500, 'could not retrieve Pull Request root')
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

            if job_url.nil?
              GithubStatus.set_status(repo_url, pr_sha, 'error', 'No Cyclid job file found')
              return_failure(400, 'not a Cyclid repository')
            end

            # Pull down the job file
            begin
              job_file_url = URI(job_url)
              Cyclid.logger.info "Retrieving PR job from #{job_url}"

              request = Net::HTTP::Get.new(job_file_url)
              request.add_field 'Authorization', 'token 9fdeb8455415c9c9d1a91a73410a7bf91b5b63c2'

              http = Net::HTTP.new(job_file_url.hostname, job_file_url.port)
              http.use_ssl = (job_file_url.scheme == 'https')
              response = http.request(request)
              raise "couldn't get Cyclid job" unless response.code == '200'

              job_blob = Oj.load response.body
              job_definition = Oj.load(Base64.decode64(job_blob['content']))
            rescue StandardError => ex
              GithubStatus.set_status(repo_url, pr_sha, 'error', "Couldn't retrieve Cyclid job file")
              Cyclid.logger.error "failed to retrieve Github Pull Request job: #{ex}"
              raise
            end

            Cyclid.logger.debug "job_definition=#{job_definition}"

            begin
              callback = GithubCallback.new(repo_url, pr_sha)
              job_json = job_from_definition(job_definition, callback)
            rescue StandardError => ex
              GithubStatus.set_status(repo_url, pr_sha, 'failure', ex)
              return_failure(500, 'job failed')
            end
          end
        end

        module GithubStatus
          def self.set_status(repo_url, pr_sha, state, description)
            # Update the PR status
            begin
              status_url = URI("#{repo_url}/statuses/#{pr_sha}")
              status = {state: state,
                        target_url: 'http://cyclid.io',
                        description: description,
                        context: 'continuous-integration/cyclid'}

              request = Net::HTTP::Post.new(status_url)
              request.content_type = 'application/json'
              request.add_field 'Authorization', 'token 9fdeb8455415c9c9d1a91a73410a7bf91b5b63c2'
              request.body = status.to_json

              http = Net::HTTP.new(status_url.hostname, status_url.port)
              http.use_ssl = (status_url.scheme == 'https')
              response = http.request(request)

              case response
              when Net::HTTPSuccess, Net::HTTPRedirection
                Cyclid.logger.info "updated PR status to #{state}"
              else
                Cyclid.logger.error "update PR status failed: #{response}"
                raise
              end
            rescue StandardError => ex
              Cyclid.logger.error "couldn't set status for PR #{pr_sha}"
              raise
            end
          end
        end

        # XXX Move me
        class Callback
          def completion(status)
          end

          def status_changed(status)
          end

          def log_write(data)
          end
        end

        class GithubCallback < Callback
          def initialize(repo_url, pr_sha)
            @repo_url = repo_url
            @pr_sha = pr_sha
          end

          def completion(status)
            if status == true
              state = 'success'
              message = 'Build job completed successfuly'
            else
              state = 'failure'
              message = 'Build job failed'
            end
            GithubStatus.set_status(@repo_url, @pr_sha, state, message)
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
