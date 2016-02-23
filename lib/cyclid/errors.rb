module Cyclid
  # Module for the Cyclid API
  module API
    # Error codes, for REST etc. statuses
    module Errors
      # Identifiers for HTTP JSON error bodies
      module HTTPErrors
        # Success
        NO_ERROR = 0
        # Something caught an exception
        INTERNAL_ERROR = 1
        # The JSON in the request body could not be parsed
        INVALID_JSON = 2
        # Invalid username or password, or not an admin
        AUTH_FAILURE = 3
        # A unique entry already exists
        DUPLICATE = 4

        # User does not exist
        INVALID_USER = 10
        # Organization does not exist
        INVALID_ORG = 11
        # Stage does not exist
        INVALID_STAGE = 12
        # No plugin found for the given action
        INVALID_ACTION = 13
      end
    end

    # Internal exceptions
    module Exceptions
      # Base class for all internal Cyclid exceptions
      class CyclidError < StandardError
      end
    end
  end
end
