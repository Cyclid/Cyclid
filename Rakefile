# encoding: utf-8
# frozen_string_literal: true

begin
  require 'bundler/setup'
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require 'rubygems/tasks'
Gem::Tasks.new

begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    abort 'Rubocop is not available.'
  end
end

begin
  require 'yard'
rescue LoadError
  task :yard do
    abort 'YARD is not available.'
  end
end

ENV['RACK_ENV'] = 'development'
require_relative 'app/db'

require 'sinatra/activerecord/rake'

ENV['CYCLID_CONFIG'] = File.join(%w(config development))

task :db_init do
  Rake::Task['db:migrate'].invoke
  system 'bin/cyclid-db-init'
end

task :doc do
  YARD::CLI::Yardoc.run('--list-undoc', '--hide-api', 'REST', '--output-dir', 'doc/api')
  YARD::CLI::Yardoc.run('--list-undoc', '--api', 'REST', '--output-dir', 'doc/rest')
end

task :rackup do
  system 'rackup'
end

task :guard do
  system 'guard'
end

task :redis do
  require 'redis'
  exec 'redis-server'
end

task :sidekiq do
  exec 'sidekiq -r ./init.rb'
end

task :default do
  Rake::Task['rackup'].invoke
end
