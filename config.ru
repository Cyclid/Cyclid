# encoding: utf-8
#
# Copyright 2016 Liqwyd Ltd
#
# Authors: Kristian Van Der Vliet <vanders@liqwyd.com>
require 'sinatra'
require File.dirname(__FILE__) + '/init'

run Cyclid::API 
