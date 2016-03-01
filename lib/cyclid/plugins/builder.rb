# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Base class for BuildHost
      class BuildHost < Hash
        def initialize(args)
          args.each do |key, value|
            self[key.to_sym] = value
          end
        end

        # Return the information needed (hostname/IP, username, password if there
        # is one) to create a Transport to this host, in a normalized form.
        def connect_info
          [self[:host], self[:username], self[:password]]
        end

        # Return a list of acceptable Transports that can be used to connect to this
        # host.
        def transports
          # XXX Maybe create some constants for "well known" Transports such as 'ssh'
          []
        end

        # Return free-form data about this host that may be useful to the build
        # process and can be merged into the Job context. This may be a subset of the
        # data for this BuildHost, or the full set.
        def context_info
          dup
        end
      end

      # Base class for Builders
      class Builder < Base
        # Create a build host, probably on a remote system, and return information
        # about it in a BuildHost object that encapsulates the information about it.
        def initialize(*args)
        end

        # Get or create a build host that can be used by a job. Args will be things
        # like the OS & version required, taken from the 'environment' section of the
        # job definition.
        #
        # The Builder can call out to external service E.g. AWS, DO, RAX etc. or
        # return an existing instance from a pool
        def get(*args)
        end

        # XXX Do we want prepare() & destroy() methods on the BuildHost, instead?

        # Prepare the build host for the job, if required E.g. install any extra
        # packages that are listed in the 'environment' section of the job definition.
        def prepare(_transport, _buildhost, _env = {})
        end

        # Shut down/release/destroy (if appropriate) the build host
        def release(_transport, _buildhost)
        end
      end
    end
  end
end

require_rel 'builder/*.rb'
