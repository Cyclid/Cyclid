require 'warden'

module Cyclid
  module Strategies
    module HMAC
      # Authenticate via. HMAC
      Warden::Strategies.add(:hmac) do
        def valid?
          request.env['HTTP_AUTHORIZATION'].is_a? String and \
            request.env['HTTP_AUTHORIZATION'] =~ %r{^HMAC .*$}
        end

        def authenticate!
          begin
            authorization = request.env['HTTP_AUTHORIZATION']
            username, hmac = authorization.match(%r{^HMAC (.*):(.*)$}).captures

            # The nonce may be empty; that isn't an error and the signature
            # will validate with a Nil nonce
            nonce = request.env['HTTP_X_HMAC_NONCE']
          rescue
            fail! 'invalid HMAC'
          end

          user = User.find_by(username: username)
          if user.nil?
            fail! 'invalid user'
          end

          begin
            method = request.env['REQUEST_METHOD']
            path = request.env['PATH_INFO']
            date = request.env['HTTP_DATE']

            Cyclid.logger.debug "user=#{user.username} method=#{method} path=#{path} date=#{date} HMAC=#{hmac} nonce=#{nonce}"

            signer = Cyclid::HMAC::Signer.new
            if signer.validate_signature(hmac, {secret: user.secret, method: method, path: path, date: date, nonce: nonce})
              success! user
            else
              fail! 'invalid user'
            end
          rescue Exception => ex
            Cyclid.logger.debug "failure during HMAC authentication: #{ex}"
            fail! 'invalid headers'
          end
        end
      end
    end
  end
end
