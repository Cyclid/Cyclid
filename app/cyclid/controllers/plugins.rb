# frozen_string_literal: true
# Copyright 2017 Liqwyd Ltd.
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

# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # API endpoints for plugins information
    # @api REST
    class PluginController < ControllerBase
      include Errors::HTTPErrors

      # Return plugin metadata
      get '/plugins' do
        authorized_for!(params[:name], Operations::READ)

        metadata = []
        Cyclid.plugins.all.each do |plugin|
          metadata << plugin.metadata
        end

        return metadata.to_json
      end
    end

    # Register this controller
    Cyclid.controllers << PluginController
  end
end
