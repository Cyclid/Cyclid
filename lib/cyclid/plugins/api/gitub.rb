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

          # Return a reference to the plugin that is associated with this
          # controller; used by the lower level code.
          def controller_plugin
            Cyclid.plugins.find('github', Cyclid::API::Plugins::Api)
          end

          def post(data, headers, config)
            Cyclid.logger.debug "in GithubMethods::post: config=#{config}"

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
              result = gh_pull_request(data, config)
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
          def gh_pull_request(data, config)
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

            api_url = URI(pr['head']['repo']['url'])
            html_url = URI(pr['base']['repo']['html_url'])

            # Get an OAuth token, if one is set for this repo
            auth_token = nil
            config['repository_keys'].each do |entry|
              auth_token = entry['token'] if entry['url'] == html_url
            end

            # Set the PR to 'pending'
            GithubStatus.set_status(api_url, pr_sha, 'pending', 'Waiting for build')

            # Get the Pull Request
            begin
              pr_url = URI("#{api_url}/git/trees/#{pr_sha}")
              Cyclid.logger.debug "Getting root for #{pr_url}"

              request = Net::HTTP::Get.new(pr_url)
              request.add_field 'Authorization', "token #{auth_token}" \
                unless auth_token.nil?

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
              GithubStatus.set_status(api_url, pr_sha, 'error', 'No Cyclid job file found')
              return_failure(400, 'not a Cyclid repository')
            end

            # Pull down the job file
            begin
              job_file_url = URI(job_url)
              Cyclid.logger.info "Retrieving PR job from #{job_url}"

              request = Net::HTTP::Get.new(job_file_url)
              request.add_field 'Authorization', "token #{auth_token}" \
                unless auth_token.nil?

              http = Net::HTTP.new(job_file_url.hostname, job_file_url.port)
              http.use_ssl = (job_file_url.scheme == 'https')
              response = http.request(request)
              raise "couldn't get Cyclid job" unless response.code == '200'

              job_blob = Oj.load response.body
              job_definition = Oj.load(Base64.decode64(job_blob['content']))
            rescue StandardError => ex
              GithubStatus.set_status(api_url, pr_sha, 'error', "Couldn't retrieve Cyclid job file")
              Cyclid.logger.error "failed to retrieve Github Pull Request job: #{ex}"
              raise
            end

            Cyclid.logger.debug "job_definition=#{job_definition}"

            begin
              callback = GithubCallback.new(api_url, pr_sha)
              job_json = job_from_definition(job_definition, callback)
            rescue StandardError => ex
              GithubStatus.set_status(api_url, pr_sha, 'failure', ex)
              return_failure(500, 'job failed')
            end
          end
        end

        module GithubStatus
          def self.set_status(api_url, pr_sha, auth_token state, description)
            # Update the PR status
            begin
              status_url = URI("#{api_url}/statuses/#{pr_sha}")
              status = {state: state,
                        target_url: 'http://cyclid.io',
                        description: description,
                        context: 'continuous-integration/cyclid'}

              request = Net::HTTP::Post.new(status_url)
              request.content_type = 'application/json'
              request.add_field 'Authorization', "token #{auth_token}" \
                unless auth_token.nil?
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
          def initialize(api_url, pr_sha)
            @api_url = api_url
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
            GithubStatus.set_status(@api_url, @pr_sha, state, message)
          end
        end
      end

      # API extension for Github hooks 
      class Github < Api
        def self.controller
          return ApiExtension::Controller.new(ApiExtension::GithubMethods)
        end

        class << self
          # Merge the given config into the current config & validate
          def update_config(config, new)
            Cyclid.logger.debug "config=#{config} new=#{new}"

            if new.key? 'repository_tokens'
              Cyclid.logger.debug 'updating repository tokens'

              new_tokens = new['repository_tokens']
              current_tokens = config['repository_tokens']

              raise 'repository_tokens must be an array' \
                unless new_tokens.is_a? Array

              # Merge the current list of tokens with the new list of tokens;
              # we have to do this in a 'roundabout fashion:
              #
              # 1. Convert both into a hash, with the url as the key and
              #    the original hash itself as the value. E.g.
              #    {url: 'example.com', token: 'abcdef'} becomes
              #    {'exmaple.com': {url: 'example.com', token: 'abcdef'}}
              # 2. Merge the new hash into the current hash; this will
              #    over-write any existing entries.
              # 3. Obtain the values of the the resulting merged object, which
              #    is an array of the original hashes.
              #
              # Thanks, Stackoverflow!
              new_hash = Hash[new_tokens.map{|h| [h['url'], h]}]
              current_hash = Hash[current_tokens.map{|h| [h['url'], h]}]

              merged = current_hash.merge(new_hash).values

              # Delete any entries where the token value is nil
              merged.delete_if do |entry|
                entry['token'].nil?
              end

              config['repository_tokens'] = merged
            end

            if new.key? 'hmac_secret'
              Cyclid.logger.debug 'updating HMAC secret'
              config['hmac_secret'] = new['hmac_secret']
            end

            return config
          end

          # Default configuration
          def default_config
            config = {}
            config['repository_tokens'] = []
            config['hmac_secret'] = nil

            return config
          end

          # Github plugin configuration schema
          def config_schema
            schema = []
            schema << {name: 'repository_tokens',
                       type: 'hash-list',
                       description: 'Repository OAuth tokens',
                       default: []}
            schema << {name: 'hmac_secret',
                       type: 'string',
                       description: 'Github HMAC signing secret',
                       default: nil}

            return schema
          end
        end

        # Register this plugin
        register_plugin 'github'
      end
    end
  end
end
