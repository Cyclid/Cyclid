# encoding: utf-8
#
# Copyright 2016 Liqwyd Ltd
#
# Authors: Kristian Van Der Vliet <vanders@liqwyd.com>
require 'sinatra'
require 'sidekiq/web'
require File.dirname(__FILE__) + '/init'

map '/' do
  run Cyclid::API::App
end

map '/sidekiq' do
  run Sidekiq::Web
end
