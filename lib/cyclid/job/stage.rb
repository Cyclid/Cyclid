# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Job related classes
    module Job
      # Non-AR model for Stages. Using a wrapper allows us to create an ad-hoc
      # stage (I.e. one that is not stored in the database) or load a stage
      # from the database and merge in over-rides without risking modifying
      # the database object.
      class StageView
        attr_reader :name, :version, :steps
        attr_accessor :on_success, :on_failure

        def initialize(arg)
          if arg.is_a? Cyclid::API::Stage
            @name = arg.name
            @version = arg.version
            @steps = arg.steps.map{ |step| step.serializable_hash }
          elsif arg.is_a? Hash
            arg.symbolize_keys!

            raise ArgumentError 'name is required' unless arg.key? :name

            @name = arg[:name]
            @name = arg.fetch(:version, '1.0.0')

            # XXX Steps?
          end
        end
      end
    end
  end
end
