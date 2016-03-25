# encoding: utf-8

begin
  require 'bundler/setup'
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

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

  YARD::Rake::YardocTask.new
rescue LoadError
  task :yard do
    abort 'YARD is not available.'
  end
end

ENV['RACK_ENV'] = 'development'
require_relative 'lib/db'

require 'sinatra/activerecord/rake'

task :doc do
  Rake::Task['yard'].invoke
  YARD::CLI::Stats.run('--list-undoc')
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
