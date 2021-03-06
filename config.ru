# encoding: utf-8
# frozen_string_literal: true
#
# Copyright 2016 Liqwyd Ltd
#
# Authors: Kristian Van Der Vliet <vanders@liqwyd.com>
require 'sinatra'
require 'sidekiq/web'

require 'cyclid/app'

configure :production do
  map '/' do
    app = Cyclid::API::App
    app.set :bind, '0.0.0.0'
    app.set :port, 8361
    app.run!
  end
end

configure :development do
  map '/' do
    app = Cyclid::API::App
    app.set :bind, '127.0.0.1'
    app.set :port, 8361
    app.run!
  end

  map '/sidekiq' do
    run Sidekiq::Web
  end
end
