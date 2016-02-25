# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Job related classes
    module Job
      class JobView
        attr_reader :name, :version

        def initialize(job, org)
          # Job is a hash (converted from JSON or YAML)
          job.symbolize_keys!

          @name = job[:name]
          @version = job[:version] || '1.0.0'
          @environment = job[:environment]

          # Build a single unified list of StageViews
          @stages, @sequence = build_stage_collection(job, org)
        end

        # Return everything, serialized into a hash
        def to_hash
          hash = {}
          hash[:name] = @name
          hash[:version] = @version
          hash[:environment] = @environment
          hash[:stages] = @stages.map{ |stage| Oj.dump(stage) }
          hash[:sequence] = @sequence

          return hash
        end

        private

        # Create the ad-hoc StageViews & combine them with the Stages defined
        # in the Job, returning an array of StageViews & a list of the Stages
        # in the order to be run.
        def build_stage_collection(job, org)
          # Create a JobStage for each ad-hoc stage defined in the job and
          # add it to the list of stages for this job
          stages = {}
          sequence = []
          begin
            job[:stages].each do |stage|
              stage_view = StageView.new(stage)
              stages[stage_view.name.to_sym] = stage_view
            end if job.key? :stages
          rescue StandardError => ex
            # XXX Probably something wrong with the definition; re-raise it? Or
            # maybe we get rid of this block and catch it further up (in the
            # controller?)
            Cyclid.logger.info ex
          end

          # XXX for each stage in the job, it's either already in the list of
          # stages (how would we find it?) or we need to load it from the
          # database, create a JobStage from it, and add it to the list of
          # stages
          job[:sequence].each do |job_stage|
            job_stage.symbolize_keys!

            raise ArgumentError 'invalid stage definition' \
              unless job_stage.key? :stage

            # Store the job in the sequence so that we can run the stages in
            # the correct order
            name = job_stage[:stage]
            Cyclid.logger.debug "stage name: #{name}"
            sequence << name

            # Try to find the stage
            if stages.key? name.to_sym
              # Ad-hoc stage defined in the job
              stage_view = stages[name.to_sym]
            else
              # Try to find a matching pre-defined stage

              if job_stage.key? :version
                stage = org.stages.find_by(name: name, version: job_stage[:version])
              else
                # If no version given, get the latest
                stage = org.stages.where(name: name).last
              end

              raise ArgumentError "stage #{name}:#{version} not found" \
                if stage.nil?

              stage_view = StageView.new(stage)
            end

            # Merge in the options specified in this job stage
            stage_view.on_success = job_stage[:on_success]
            stage_view.on_failure = job_stage[:on_failure]

            # Store the modified StageView
            stages[stage_view.name.to_sym] = stage_view
          end

          return [stages, sequence]
        end

      end
    end
  end
end 
