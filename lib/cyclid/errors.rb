module Cyclid
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
    end
  end
end
