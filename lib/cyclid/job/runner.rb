# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Job related classes
    module Job
      # Run a job
      class Runner
        include Constants::JobStatus

        def initialize(job_id, job_definition, notifier)
          # The notifier for updating the job status & writing to the log
          # buffer
          @notifier = notifier

          # Create an initial job context (more will be added as the job runs)
          @ctx = { job_id: job_id }

          # Un-serialize the job
          begin
            @job = Oj.load(job_definition, symbol_keys: true)
            Cyclid.logger.debug "job=#{@job.inspect}"

            environment = @job[:environment]
          rescue StandardError
            Cyclid.logger.error "couldn't un-serialize job for job ID #{job_id}"
            raise 'job failed'
          end

          @ctx[:name] = @job[:name]
          @ctx[:version] = @job[:version]
          @ctx[:environment] = environment

          begin
            # We're off!
            @notifier.status = WAITING

            # Create a Builder
            @builder = create_builder

            # Obtain a host to run the job on
            @notifier.write "#{Time.now} : Obtaining build host...\n"
            @build_host = request_build_host(@builder, environment)

            # Add some build host details to the build context
            @ctx.merge! @build_host.context_info

            # Connect a transport to the build host; the notifier is a proxy
            # to the log buffer
            @transport = create_transport(@build_host, @notifier)

            # Prepare the host
            provisioner = create_provisioner(@build_host)

            @notifier.write "#{Time.now} : Preparing build host...\n#{'=' * 79}\n"
            provisioner.prepare(@transport, @build_host, environment)

            # Check out sources
            @notifier.write "#{'=' * 79}\n#{Time.now} : Checking out source...\n"
            checkout_sources(@transport, @job[:sources])
          rescue StandardError => ex
            Cyclid.logger.error "job runner failed: #{ex}"

            @notifier.status = FAILED
            @notifier.ended = Time.now.to_s

            begin
              @builder.release(@transport, @build_host) if @build_host
              @transport.close if @transport
            rescue ::Net::SSH::Disconnect # rubocop:disable Lint/HandleExceptions
              # Ignored
            end

            raise # XXX Raise an internal exception
          end
        end

        # Run the stages.
        #
        # Start with the first stage, and execute all of the steps until
        # either one fails, or there are no more steps. The follow the
        # on_success & on_failure handlers to the next stage. If no
        # handler is defined, stop.
        def run
          status = STARTED
          @notifier.status = status
          @notifier.write "#{'=' * 79}\n#{Time.now} : Job started. " \
                          "Context: #{@ctx.stringify_keys}\n"

          # Run the Job stage actions
          stages = @job[:stages]
          sequence = @job[:sequence].first

          loop do
            # Find the stage
            raise 'stage not found' unless stages.key? sequence.to_sym

            # Un-serialize the stage into a StageView
            stage_definition = stages[sequence.to_sym]
            stage = Oj.load(stage_definition, symbol_keys: true)

            @notifier.write "#{'-' * 79}\n#{Time.now} : " \
                            "Running stage #{stage.name} v#{stage.version}\n"

            # Run the stage
            success, rc = run_stage(stage)

            Cyclid.logger.info "stage #{(success ? 'succeeded' : 'failed')} and returned #{rc}"

            # Decide which stage to run next depending on the outcome of this
            # one
            if success
              sequence = stage.on_success
            else
              sequence = stage.on_failure

              # Remember the failure while the failure handlers run
              status = FAILING
              @notifier.status = status
            end

            # Stop if we have no further sequences
            break if sequence.nil?
          end

          # Either all of the stages succeeded, and thus the job suceeded, or
          # (at least one of) the stages failed, and thus the job failed
          if status == FAILING
            @notifier.status = FAILED
            success = false
          else
            @notifier.status = SUCCEEDED
            success = true
          end

          # We no longer require the build host & transport
          begin
            @builder.release(@transport, @build_host)
            @transport.close
          rescue ::Net::SSH::Disconnect # rubocop:disable Lint/HandleExceptions
            # Ignored
          end

          return success
        end

        private

        # Create a suitable Builder
        def create_builder
          # Each worker creates a new instance
          builder = Cyclid.builder.new
          raise "couldn't create a builder" \
            unless builder

          return builder
        end

        # Acquire a build host from the builder
        def request_build_host(builder, environment)
          # Request a BuildHost
          build_host = builder.get(environment)
          raise "couldn't obtain a build host" unless build_host

          return build_host
        end

        # Find a transport that can be used with the build host, create one and
        # connect them together
        def create_transport(build_host, log_buffer)
          # Create a Transport & connect it to the build host
          host, username, password = build_host.connect_info
          Cyclid.logger.debug "create_transport: host: #{host} " \
                                            "username: #{username} " \
                                            "password: #{password}"

          # Try to match a transport that the host supports, to a transport we know how
          # to create; transports should be listed in the order they're preferred.
          transport_plugin = nil
          build_host.transports.each do |t|
            transport_plugin = Cyclid.plugins.find(t, Cyclid::API::Plugins::Transport)
          end

          raise "couldn't find a valid transport from #{build_host.transports}" \
            unless transport_plugin

          # Connect the transport to the build host
          transport = transport_plugin.new(host: host,
                                           user: username,
                                           password: password,
                                           log: log_buffer)
          raise 'failed to connect the transport' unless transport

          return transport
        end

        # Find a provisioner that can be used with the build host and create
        # one
        def create_provisioner(build_host)
          distro = build_host[:distro]

          provisioner_plugin = Cyclid.plugins.find(distro, Cyclid::API::Plugins::Provisioner)
          raise "couldn't find a valid provisioner for #{distro}" \
            unless provisioner_plugin

          provisioner = provisioner_plugin.new
          raise 'failed to create provisioner' unless provisioner

          return provisioner
        end

        # Find and create a suitable source plugin instance for each source and have it check out
        # the given source using the transport.
        def checkout_sources(transport, sources)
          sources.each do |job_source|
            raise 'no type given in source definition' unless job_source.key? :type

            source = Cyclid.plugins.find(job_source[:type], Cyclid::API::Plugins::Source)
            raise "can't find a plugin for #{job_source[:type]} source" if source.nil?

            success = source.new.checkout(transport, job_source)
            raise "failed to check out source" unless success
          end
        end

        # Perform each action defined in the steps of the given stage, until
        # either an action fails or we run out of steps
        def run_stage(stage)
          stage.steps.each do |step|
            begin
              # Un-serialize the Action for this step
              action = Oj.load(step[:action], symbol_keys: true)
            rescue StandardError
              Cyclid.logger.error "couldn't un-serialize action for job ID #{job_id}"
              raise 'job failed'
            end

            # Run the action
            action.prepare(transport: @transport, ctx: @ctx)
            success, rc = action.perform(@notifier)

            return [false, rc] unless success
          end

          return [true, 0]
        end
      end
    end
  end
end
