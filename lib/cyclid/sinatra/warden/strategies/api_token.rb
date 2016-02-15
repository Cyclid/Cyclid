require 'warden'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Warden Strategies
    module Strategies
      # API Token based strategy
      module APIToken
        # Authenticate via. an API token
        Warden::Strategies.add(:api_token) do
          def valid?
            request.env['HTTP_AUTHORIZATION'].is_a? String and \
              request.env['HTTP_AUTHORIZATION'] =~ /^Token .*$/
          end

          def authenticate!
            begin
              authorization = request.env['HTTP_AUTHORIZATION']
              username, token = authorization.match(/^Token (.*):(.*)$/).captures
            rescue
              fail! 'invalid API token'
            end

            user = User.find_by(username: username)
            if user.nil?
              fail! 'invalid user'
            else
              if user.secret == token
                success! user
              else
                fail! 'invalid user'
              end
            end
          end
        end
      end
    end
  end
end
