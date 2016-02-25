# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Job related classes
    module Job
      # Run a job
      class Runner
        include Constants::JobStatus

        def initialize(job_definition, job_id)
          # Obtain the JobRecord so that it can be attached to the LogBuffer
          # and updated as the job runs
          # XXX A remote worker won't have access to JobRecords (they'll update
          # the API application via. messages) so this is entirely invalid!
          @job_record = JobRecord.find(job_id)

          # Un-serialize the job
          begin
            @job = Oj.load(job_definition, symbol_keys: true)
            Cyclid.logger.debug "job=#{@job.inspect}"

            environment = @job[:environment]
          rescue StandardError => ex
            Cyclid.logger.error "couldn't un-serialize job for job ID #{job_id}"
            raise 'job failed'
          end

          begin
            # Create a LogBuffer
            @log_buffer = LogBuffer.new(@job_record)

            # We're off!
            @job_record.status = WAITING
            @job_record.save!

            # Create a Builder
            builder = get_builder(environment)

            # Obtain a host to run the job on
            build_host = get_build_host(builder)

            # Connect a transport to it
            @transport = get_transport(build_host, @log_buffer)

            # Prepare the host
            builder.prepare(@transport, build_host, environment)
          rescue StandardError => ex
            Cyclid.logger.error "job runner failed: #{ex}"

            @job_record.status = FAILED
            @job_record.ended = Time.now.to_s
            @job_record.save!

            raise # XXX Raise an internal exception
          end
        end

        def run
          @job_record.status = STARTED
          @job_record.save!

          # Run the Job stage actions
          stages = @job[:stages]
          @job[:sequence].each do |sequence|
            Cyclid.logger.debug "sequence=#{sequence.inspect}"

            # Find the stage
            raise 'stage not found' unless stages.key? sequence.to_sym

            # Un-serialize the stage into a StageView
            stage_definition = stages[sequence.to_sym]
            stage = Oj.load(stage_definition, symbol_keys: true)

            Cyclid.logger.debug "got stage=#{stage.inspect}"

            stage.steps.each do |step|
              Cyclid.logger.debug "step=#{step.inspect}"

              # Un-serialize the Action for this step
              action = Oj.load(step[:action], symbol_keys: true)
              Cyclid.logger.debug "got action=#{action.inspect}"

              # Run the action
              # XXX We need a proper job context! Should be a hash created
              # initialize (& updated by run?)
              action.prepare(transport: @transport, ctx: {})
              success, rc = action.perform(@log_buffer)

              # XXX This is wrong; if the Step has failed, the Stage has
              # failed, and we should run the on_failure Stage
              if !success
                @job_record.status = FAILED
                @job_record.save!

                raise "action failed with exit status #{rc}"
              end
            end
          end

          @job_record.status = SUCCEEDED
          @job_record.save!

          return true
        end

        private

        def get_builder(environment)
          # XXX Do we need a Builder per. Runner, or can we have a single
          # global Builder and let the get() method do all the hard work for
          # each Builder?
          builder_plugin = Cyclid.plugins.find('mist', Cyclid::API::Plugins::Builder)
          raise "couldn't find a builder plugin" unless builder_plugin

          builder = builder_plugin.new(os: environment[:os])
          raise "couldn't create a builder with environment #{environment}" \
            unless builder

          Cyclid.logger.debug "got a builder: #{builder.inspect}"

          return builder
        end

        def get_build_host(builder)
          # Request a BuildHost
          build_host = builder.get
          raise "couldn't obtain a build host" unless build_host

          return build_host
        end

        def get_transport(build_host, log_buffer)
          # Create a Transport & connect it to the build host
          host, username, password = build_host.connect_info
          Cyclid.logger.debug "host: #{host} username: #{username} password: #{password}"

          # Try to match a transport that the host supports, to a transport we know how
          # to create; transports should be listed in the order they're preferred.
          transport_plugin = nil
          build_host.transports.each do |t|
            Cyclid.logger.debug "trying transport '#{t}'.."
            transport_plugin = Cyclid.plugins.find(t, Cyclid::API::Plugins::Transport)
          end

          raise "couldn't find a valid transport from #{build_host.transports}" \
            unless transport_plugin

          Cyclid.logger.debug 'got a valid transport'

          # Connect the transport to the build host
          transport = transport_plugin.new(host: host, user: username, password: password, log: log_buffer)
          raise "failed to connect the transport" unless transport

          return transport
        end

      end
    end
  end
end
