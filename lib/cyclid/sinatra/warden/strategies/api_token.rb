require 'warden'

module Cyclid
  module Strategies
    module APIToken
      # Authenticate via. an API token
      Warden::Strategies.add(:api_token) do
        def valid?
          request.env['HTTP_AUTHORIZATION'].is_a? String and \
            request.env['HTTP_AUTHORIZATION'] =~ %r{^Token .*$}
        end

        def authenticate!
          begin
            authorization = request.env['HTTP_AUTHORIZATION']
            username, token = authorization.match(%r{^Token (.*):(.*)$}).captures
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
