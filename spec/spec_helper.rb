# frozen_string_literal: true
require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/test/'
  add_filter '/db/'

  add_group 'Controllers', 'app/cyclid/controller'
  add_group 'Models', 'app/cyclid/models'
  add_group 'Job', 'app/cyclid/job'
  add_group 'Plugins', 'app/cyclid/plugins'
end

require 'spec_setup'
