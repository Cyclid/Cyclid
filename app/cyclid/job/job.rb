# frozen_string_literal: true
# Copyright 2016 Liqwyd Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Job related classes
    module Job
      # Non-ActiveRecord class which holds a complete Job, complete with
      # serialised stages and the resolved sequence.
      class JobView
        attr_reader :name, :version

        def initialize(job, context, org)
          @name = job[:name]
          @version = job[:version] || '1.0.0'

          @context = context
          @organization = org.name
          @environment = job[:environment]
          @sources = job[:sources] || []
          @secrets = setec_astronomy(org, (job[:secrets] || {}))

          # Build a single unified list of StageViews
          @stages, @sequence = build_stage_collection(job, org)
        end

        # Return everything, serialized into a hash
        def to_hash
          hash = {}
          hash[:name] = @name
          hash[:version] = @version
          hash[:context] = @context
          hash[:organization] = @organization
          hash[:environment] = @environment
          hash[:sources] = @sources
          hash[:secrets] = @secrets
          hash[:stages] = @stages.each_with_object({}) do |(name, stage), h|
            h[name.to_sym] = Oj.dump(stage)
          end
          hash[:sequence] = @sequence

          return hash
        end

        private

        # Too Many Secrets
        def setec_astronomy(org, secrets)
          # Create the RSA private key
          private_key = OpenSSL::PKey::RSA.new(org.rsa_private_key)

          secrets.hmap do |key, secret|
            { key => private_key.private_decrypt(Base64.decode64(secret)) }
          end
        end

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
            Cyclid.logger.info "ad-hoc stage creation failed: #{ex}"
            raise
          end

          # For each stage in the job, it's either already in the list of
          # stages because we created on as an ad-hoc stage, or we need to load
          # it from the database, create a JobStage from it, and add it to the
          # list of stages
          job_sequence = job[:sequence]
          job_sequence.each do |job_stage|
            job_stage.symbolize_keys!

            raise ArgumentError, 'invalid stage definition' \
              unless job_stage.key? :stage

            # Store the job in the sequence so that we can run the stages in
            # the correct order
            name = job_stage[:stage]
            sequence << name

            # Try to find the stage
            if stages.key? name.to_sym
              # Ad-hoc stage defined in the job
              stage_view = stages[name.to_sym]
            else
              # Try to find a matching pre-defined stage
              stage = if job_stage.key? :version
                        org.stages.find_by(name: name, version: job_stage[:version])
                      else
                        # If no version given, get the latest
                        org.stages.where(name: name).last
                      end

              raise ArgumentError, "stage #{name}:#{version} not found" \
                if stage.nil?

              stage_view = StageView.new(stage)
            end

            # Merge in the options specified in this job stage. If the
            # on_success or on_failure stages are not already in the sequence,
            # append them to the end.
            stage_success = { stage: job_stage[:on_success] }
            job_sequence << stage_success \
              unless job_stage[:on_success].nil? or \
                     stage?(job_sequence, job_stage[:on_success])

            # Set the on_success handler; if no explicit hander is defined, use
            # the next stage in the sequence
            success_stage = if job_stage[:on_success]
                              job_stage[:on_success]
                            else
                              next_stage(job_sequence, job_stage)
                            end
            stage_view.on_success = success_stage

            # Now set the on_failure handler
            stage_failure = { stage: job_stage[:on_failure] }
            job_sequence << stage_failure \
              unless job_stage[:on_failure].nil? or \
                     stage?(job_sequence, job_stage[:on_failure])
            stage_view.on_failure = job_stage[:on_failure]

            # Merge in any modifiers
            stage_view.only_if = job_stage[:only_if]
            stage_view.not_if = job_stage[:not_if]
            stage_view.fail_if = job_stage[:fail_if]

            # Store the modified StageView
            stages[stage_view.name.to_sym] = stage_view
          end

          return [stages, sequence]
        end

        # Search for a stage in the sequence, by name
        def stage?(sequence, name)
          found = false
          sequence.each do |stage|
            found = stage[:stage] == name || stage['stage'] == name
            break if found
          end
          return found
        end

        # Get the directly proceeding stage in the sequence
        def next_stage(sequence, stage)
          idx = sequence.index stage

          next_stage = sequence.at(idx + 1)
          next_stage.nil? ? nil : next_stage['stage']
        end
      end
    end
  end
end
