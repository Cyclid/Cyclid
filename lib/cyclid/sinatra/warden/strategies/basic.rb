require 'warden'
require 'bcrypt'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Warden Strategies
    module Strategies
      # HTTTP Basic authentication based strategy
      module Basic
        # Authenticate via. HTTP Basic auth.
        Warden::Strategies.add(:basic) do
          def valid?
            request.env['HTTP_AUTHORIZATION'].is_a? String and \
              request.env['HTTP_AUTHORIZATION'] =~ /^Basic .*$/
          end

          def authenticate!
            begin
              authorization = request.env['HTTP_AUTHORIZATION']
              digest = authorization.match(/^Basic (.*)$/).captures.first

              user_pass = Base64.decode64(digest)
              username, password = user_pass.split(':')
            rescue
              fail! 'invalid digest'
            end

            user = User.find_by(username: username)
            if user.nil?
              fail! 'invalid user'
            elsif BCrypt::Password.new(user.password).is_password? password
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
