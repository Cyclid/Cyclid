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

require 'mail'
require 'erb'
require 'premailer'

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
          @color = args[:color] || 'dodgerblue'
        end

        # Send an email to the configured recipient; the message is rendered
        # into text & HTML via. an ERB template which inserts additional
        # information from the context
        def perform(log)
          begin
            # Retrieve the server-wide email configuration
            config = Cyclid.config.plugins
            email_config = load_email_config(config)

            Cyclid.logger.debug "sending via. #{email_config[:server]}:#{email_config[:port]} " \
                                "as #{email_config[:from]}"

            # Add the job context
            to = @to % @ctx
            subject = @subject % @ctx
            message = @message % @ctx

            # Create a binding for the text & HTML ERB templates
            info = { color: @color, title: subject }

            bind = binding
            bind.local_variable_set(:info, info)
            bind.local_variable_set(:ctx, @ctx)
            bind.local_variable_set(:message, message)

            # Generate text email from a template
            template_path = File.expand_path(File.join(__FILE__, '..', 'email', 'text.erb'))
            template = ERB.new(File.read(template_path), nil, '%<>-')

            text_body = template.result(bind)

            # Generate the HTML email from a template
            template_path = File.expand_path(File.join(__FILE__, '..', 'email', 'html.erb'))
            template = ERB.new(File.read(template_path), nil, '%<>-')

            html = template.result(bind)

            # Run the HTML through Premailer to inline the styles
            premailer = Premailer.new(html,
                                      with_html_string: true,
                                      warn_level: Premailer::Warnings::SAFE)
            html_body = premailer.to_inline_css

            # Create the email
            mail = Mail.new
            mail.from = email_config[:from]
            mail.to = to
            mail.subject = subject
            mail.text_part do
              body text_body
            end
            mail.html_part do
              content_type 'text/html; charset=UTF8'
              body html_body
            end

            # Deliver the email via. the configured server, using
            # authentication if a username & password were provided.
            log.write("sending email to #{@to}")

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

        # Load the config for the email plugin and set defaults if they're not
        # in the config
        def load_email_config(config)
          config.symbolize_keys!

          server_config = config[:email] || {}
          Cyclid.logger.debug "config=#{server_config}"

          server_config.symbolize_keys!

          # Set defaults where no server configuration is set
          server_config[:server] ||= 'localhost'
          server_config[:port] ||= 587
          server_config[:from] ||= 'cyclid@cyclid.io'

          server_config[:username] ||= nil
          server_config[:password] ||= nil

          # Load any organization specific configuration
          plugin_data = self.class.get_config(@ctx[:organization])
          Cyclid.logger.debug "using plugin config #{plugin_data}"
          plugin_config = plugin_data['config']

          # Merge the plugin configuration onto the server configuration (I.e.
          # plugin configuration over-rides server configuration) to produce
          # the final configuration
          email_config = {}
          email_config[:server] = plugin_config[:server] || server_config[:server]
          email_config[:port] = plugin_config[:port] || server_config[:port]
          email_config[:from] = plugin_config[:from] || server_config[:from]

          email_config[:username] = plugin_config[:username] || server_config[:username]
          email_config[:password] = plugin_config[:password] || server_config[:password]

          return email_config
        end

        # Static methods for handling plugin config data
        class << self
          # This plugin has configuration data
          def has_config?
            true
          end

          # Update the plugin configuration
          def update_config(current, new)
            current.merge! new
          end

          # Default configuration for the email plugin
          def default_config
            config = {}
            config['server'] = nil
            config['port'] = nil
            config['from'] = nil
            config['username'] = nil
            config['password'] = nil

            return config
          end

          # Config schema for the email plugin
          def config_schema
            schema = []
            schema << { name: 'server',
                        type: 'string',
                        description: 'SMTP server for outgoing emails',
                        default: nil }
            schema << { name: 'port',
                        type: 'integer',
                        description: 'SMTP server port to connect to',
                        default: nil }
            schema << { name: 'from',
                        type: 'string',
                        description: 'Sender email address',
                        default: nil }
            schema << { name: 'username',
                        type: 'string',
                        description: 'SMTP server username',
                        default: nil }
            schema << { name: 'password',
                        type: 'password',
                        description: 'SMTP server password',
                        default: nil }

            return schema
          end
        end
      end
    end
  end
end
