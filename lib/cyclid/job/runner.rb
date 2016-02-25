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
          @job_record = JobRecord.find(job_id)

          # Un-serialize the job
          @job = Oj.load(job_definition, symbol_keys: true)
          Cyclid.logger.debug "job=#{@job.inspect}"

          environment = @job[:environment]

          # Create a LogBuffer
          @log_buffer = LogBuffer.new(nil)

          # Create a Builder
          @job_record.status = WAITING
          @job_record.save!

          # XXX Do we need a Builder per. Runner, or can we have a single
          # global Builder and let the get() method do all the hard work for
          # each Builder?
          builder = Cyclid.plugins.find('mist', Cyclid::API::Plugins::Builder)
          mist = builder.new(os: environment[:os])

          raise "Couldn't create a builder with environment #{environment}" \
            unless mist

          Cyclid.logger.debug "got a builder: #{mist.inspect}"

          # Request a BuilderHost
          build_host = mist.get
          Cyclid.logger.debug "got a build host: #{build_host.inspect}"

          # Try to match a transport that the host supports, to a transport we know how
          # to create; transports should be listed in the order they're preferred.
          transport = nil
          build_host.transports.each do |t|
            Cyclid.logger.debug "Trying transport '#{t}'.."
            transport = Cyclid.plugins.find(t, Cyclid::API::Plugins::Transport)
          end

          raise "Couldn't find a valid transport from #{build_host.transports}" \
            unless transport

          Cyclid.logger.debug 'got a valid transport'

          # Create a Transport & connect it to the build host
          host, username, password = build_host.connect_info
          Cyclid.logger.debug "host: #{host} username: #{username} password: #{password}"

          @ssh = transport.new(host: host, user: username, password: password, log: @log_buffer)

          # Prepare the BuildHost
          mist.prepare(@ssh, build_host, environment)
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
              action.prepare(transport: @ssh, ctx: {})
              success, rc = action.perform(@log_buffer)

              # XXX: This will destroy the database
              @job_record.log = @log_buffer.log
              @job_record.save!

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
      end
    end
  end
end
