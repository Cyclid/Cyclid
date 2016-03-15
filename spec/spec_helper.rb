require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/test/'
  add_filter '/db/'
end

# Configure a test database
require 'active_record'

ENV['RACK_ENV'] = 'test'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'memory'
)
require_relative '../db/schema.rb'

# Pull in the code
require_relative '../lib/cyclid'
