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
      class SlackNotification < Action
        def initialize(args = {})
          args.symbolize_keys!

          raise 'a slack_notification action requires a message' unless args.include? :message

          # XXX Right now it also requires the Webhook URL to be set in the step, but we should
          # fall back to a default once issue #14 is resolved
          raise 'a slack_notification action requires a URL' unless args.include? :url

          @message = args[:message]
          @url = args[:url]
          @color = args[:color] || 'good'
          @note = args[:note] if args.include? :note
        end

        def perform(log)
          begin
            message = @message % @ctx
            url = @url % @ctx

            # Send the notification to the Slack webhook
            notifier = Slack::Notifier.new url
            notifier.username = 'Cyclid'

            if @note
              text = @note % @ctx
              note = { fallback: text, text: text, color: @color }

              res = notifier.ping message, attachments: [note]
            else
              res = notifier.ping message
            end

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
        register_plugin 'slack_notification'
      end
    end
  end
end
