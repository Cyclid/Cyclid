# encoding: utf-8
#
# Copyright 2016 Liqwyd Ltd
#
# Authors: Kristian Van Der Vliet <vanders@liqwyd.com>
require 'sinatra'
require 'sidekiq/web'
require File.dirname(__FILE__) + '/init'

map '/' do
  app = Cyclid::API::App
  app.set :bind, '0.0.0.0'
  app.set :port, 80
  app.run!
end

map '/sidekiq' do
  run Sidekiq::Web
end
