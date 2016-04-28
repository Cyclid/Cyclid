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

require 'mail'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Email notification plugin
      class Email < Action
        def initialize(args = {})
          args.symbolize_keys!

          raise 'an email action requires a message' unless args.include? :message
          @message = args[:message]

          raise 'an email action requires a recipient' unless args.include? :to
          @to = args[:to]

          @subject = args[:subject] || 'Cyclid notification'
        end

        def perform(log)
          begin
            # Retrieve the server-wide email configuration
            config = Cyclid.config.plugins
            email_config = load_email_config(config)

            Cyclid.logger.debug "sending via. #{email_config[:server]}:#{email_config[:port]} " \
                                "as #{email_config[:from]}"

            Cyclid.logger.debug "to=#{@to} subject=#{@subject} message=#{@message}"

            # Add the job context
            to = @to % @ctx
            subject = @subject % @ctx
            message = @message % @ctx

            # Create the email
            mail = Mail.new
            mail.from = email_config[:from]
            mail.to = to
            mail.subject = subject
            mail.body = message
            # XXX We could send a multi-part email with an HTML body and the
            # message rendered in via. a template.
            Cyclid.logger.debug mail.to_s

            # Deliver the email via. the configured server, using
            # authentication if a username & password were provided.
            mail.delivery_method :smtp, address: email_config[:server],
                                        port: email_config[:port],
                                        user_name: email_config[:username],
                                        password: email_config[:password]
            mail.deliver

            success = true
          rescue StandardError => ex
            log.write "#{ex.message}\n"
            success = false
          end

          [success, 0]
        end

        # Register this plugin
        register_plugin 'email'

        private

        # Load the config for the email plugi and set defaults if they're not
        # in the config
        def load_email_config(config)
          config.symbolize_keys!

          email_config = config[:email] || {}
          Cyclid.logger.debug "config=#{email_config}"

          email_config.symbolize_keys!

          email_config[:server] ||= 'localhost'
          email_config[:port] ||= 587
          email_config[:from] ||= 'cyclid@cyclid.io'

          email_config[:username] ||= nil
          email_config[:password] ||= nil

          return email_config
        end
      end
    end
  end
end
