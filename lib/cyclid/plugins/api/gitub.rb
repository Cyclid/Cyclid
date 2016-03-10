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
            html_url = URI(pr['base']['repo']['html_url'])
            pr_sha = pr['head']['sha']
            ref = pr['head']['ref']

            Cyclid.logger.debug "sha=#{pr_sha} ref=#{ref}"

            # Get some useful endpoints & interpolate the SHA for this PR
            url = pr['head']['repo']['statuses_url']
            statuses = url.gsub('{sha}', pr_sha)

            url = pr['head']['repo']['trees_url']
            trees = url.gsub('{/sha}', "/#{pr_sha}")

            # Get an OAuth token, if one is set for this repo
            Cyclid.logger.debug "attempting to find auth token for #{html_url}"
            auth_token = nil
            config['repository_tokens'].each do |entry|
              entry_url = URI(entry['url'])
              auth_token = entry['token'] if entry_url.host == html_url.host && \
                                             entry_url.path == html_url.path
            end
            Cyclid.logger.debug "auth token=#{auth_token}"

            # Set the PR to 'pending'
            GithubStatus.set_status(statuses, auth_token, 'pending', 'Preparing build')

            # Get the Pull Request
            begin
              trees_url = URI(trees)
              Cyclid.logger.debug "Getting root for #{trees_url}"

              request = Net::HTTP::Get.new(trees_url)
              request.add_field 'Authorization', "token #{auth_token}" \
                unless auth_token.nil?

              http = Net::HTTP.new(trees_url.hostname, trees_url.port)
              http.use_ssl = (trees_url.scheme == 'https')
              response = http.request(request)

              Cyclid.logger.debug response.inspect
              raise "couldn't get repository root" unless response.code == '200'

              root = Oj.load response.body
            rescue StandardError => ex
              Cyclid.logger.error "failed to retrieve Pull Request root: #{ex}"
              return_failure(500, 'could not retrieve Pull Request root')
            end

            # See if a .cyclid.yml or .cyclid.json file exists in the project
            # root
            job_url = nil
            root['tree'].each do |file|
              if file['path'] =~ /\A\.cyclid\.(json|yml)\z/
                job_url = URI(file['url'])
                break
              end
            end

            Cyclid.logger.debug "job_url=#{job_url}"

            if job_url.nil?
              GithubStatus.set_status(statuses, auth_token, 'error', 'No Cyclid job file found')
              return_failure(400, 'not a Cyclid repository')
            end

            # Pull down the job file
            begin
              Cyclid.logger.info "Retrieving PR job from #{job_url}"

              request = Net::HTTP::Get.new(job_url)
              request.add_field 'Authorization', "token #{auth_token}" \
                unless auth_token.nil?

              http = Net::HTTP.new(job_url.hostname, job_url.port)
              http.use_ssl = (job_url.scheme == 'https')
              response = http.request(request)
              raise "couldn't get Cyclid job" unless response.code == '200'

              job_blob = Oj.load response.body
              job_definition = Oj.load(Base64.decode64(job_blob['content']), symbolize_keys: true)

              # Insert this repository & branch into the sources
              #
              # XXX Could this cause collisions between the existing sources in
              # the job definition? Not entirely sure what the workflow will
              # look like.
              job_sources = job_definition[:sources] || []
              job_sources << {type: 'git', url: html_url.to_s, branch: ref, token: auth_token}
              job_definition[:sources] = job_sources
            rescue StandardError => ex
              GithubStatus.set_status(statuses, auth_token, 'error', "Couldn't retrieve Cyclid job file")
              Cyclid.logger.error "failed to retrieve Github Pull Request job: #{ex}"
              raise
            end

            Cyclid.logger.debug "job_definition=#{job_definition}"

            begin
              callback = GithubCallback.new(statuses, auth_token)
              job_id = job_from_definition(job_definition, callback)
            rescue StandardError => ex
              GithubStatus.set_status(statuses, auth_token, 'failure', ex)
              return_failure(500, 'job failed')
            end
          end
        end

        module GithubStatus
          def self.set_status(statuses, auth_token, state, description)
            # Update the PR status
            begin
              statuses_url = URI(statuses)
              status = {state: state,
                        target_url: 'http://cyclid.io',
                        description: description,
                        context: 'continuous-integration/cyclid'}

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

        # XXX Move me
        class Callback
          def completion(job_id, status)
          end

          def status_changed(job_id, status)
          end

          def log_write(job_id, data)
          end
        end

        class GithubCallback < Callback
          def initialize(statuses, auth_token)
            @statuses = statuses
            @auth_token = auth_token
          end

          def status_changed(job_id, status)
            case status
            when WAITING
              state = 'pending'
              message = "Queued job ##{job_id}."
            when STARTED
              state = 'pending'
              message = "Job ##{job_id} started."
            when FAILING
              state = 'failure'
              message = "Job ##{job_id} failed. Waiting for job to finish."
            end

            GithubStatus.set_status(@statuses, @auth_token, state, message)
          end

          def completion(job_id, status)
            if status == true
              state = 'success'
              message = "Job ##{job_id} completed successfuly."
            else
              state = 'failure'
              message = "Job ##{job_id} failed."
            end
            GithubStatus.set_status(@statuses, @auth_token, state, message)
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
