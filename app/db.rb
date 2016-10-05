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

require 'active_record'
require 'logger'

begin
  case ENV['RACK_ENV']
  when 'development'
    database = if defined? Rake
                 'sqlite3:development.db'
               else
                 Cyclid.config.database
               end

    ActiveRecord::Base.establish_connection(
      database
    )

    ActiveRecord::Base.logger = if defined? Rake
                                  Logger.new(STDERR)
                                else
                                  Cyclid.logger
                                end
  when 'production'
    ActiveRecord::Base.establish_connection(
      Cyclid.config.database
    )

    ActiveRecord::Base.logger = Cyclid.logger

    Cyclid.logger.level = Logger::INFO
  when 'test'
    Cyclid.logger.info 'In test mode; not creating database connection'
  end

rescue StandardError => ex
  abort "Failed to initialize ActiveRecord: #{ex}"
end
