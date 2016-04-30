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

require 'slack-notifier'

# Top level module for the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for Cyclid Plugins
    module Plugins
      # Slack notification plugin
      class Slack < Action
        def initialize(args = {})
          args.symbolize_keys!

          raise 'a slack action requires a subject' unless args.include? :subject

          @subject = args[:subject]
          @url = args[:url] if args.include? :url
          @color = args[:color] || 'good'
          @message = args[:message] if args.include? :message
        end

        def perform(log)
          begin
            plugin_data = self.class.get_config(@ctx[:organization])
            Cyclid.logger.debug "using plugin config #{plugin_data}"
            config = plugin_data['config']

            subject = @subject % @ctx

            url = @url || config['webhook_url']
            raise 'no webhook URL given' if url.nil?

            url = url % @ctx
            Cyclid.logger.debug "sending notification to #{url}"

            message_text = @message % @ctx if @message

            # Create a binding for the template
            bind = binding
            bind.local_variable_set(:ctx, @ctx)

            # Generate the context information from a templete
            template_path = File.expand_path(File.join(__FILE__, '..', 'slack', 'note.erb'))
            template = ERB.new(File.read(template_path), nil, '%<>-')

            context_text = template.result(bind)

            # Create a "note" and send it as part of the message
            fields = if @message
                       [{ title: 'Message', value: message_text }]
                     else
                       []
                     end
            fields << { title: 'Information',
                        value: context_text,
                        short: false }

            note = { fallback: message_text || subject,
                     color: @color,
                     fields: fields }

            # Send the notification to the Slack webhook
            notifier = ::Slack::Notifier.new url
            notifier.username = 'Cyclid'

            res = notifier.ping subject, attachments: [note]

            rc = res.code
            success = rc == '200'
          rescue StandardError => ex
            log.write "#{ex.message}\n"
            success = false
            rc = 0
          end

          [success, rc]
        end

        # Register this plugin
        register_plugin 'slack'

        # Static methods for handling plugin config data
        class << self
          def update_config(current, new)
            current.merge! new
          end

          def default_config
            config = {}
            config['webhook_url'] = nil

            return config
          end

          def config_schema
            schema = []
            schema << { name: 'webhook_url',
                        type: 'string',
                        description: 'Slack incoming webhook URL for your team',
                        default: nil }

            return schema
          end
        end
      end
    end
  end
end
