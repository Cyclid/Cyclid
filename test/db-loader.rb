#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'require_all'
require 'logger'
require 'active_record'

module Cyclid
  class << self
    attr_accessor :logger

    begin
      Cyclid.logger = Logger.new(STDERR)
     rescue Exception => ex
      abort "Failed to initialize: #{ex}"
    end
  end
end

require 'db'
require 'cyclid/models'

include Cyclid::API

def create_users
  user = User.new
  user.username = 'admin'
  user.email = 'admin@example.com'
  user.secret = 'aasecret55'
  user.new_password = 'password'
  user.save!

  user = User.new
  user.username = 'test'
  user.email = 'test@example.com'
  user.secret = 'aasecret55'
  user.new_password = 'aapassword55'
  user.save!
end

def create_organizations
  org = Organization.new
  org.name = 'cyclid'
  org.owner_email = 'cyclid@example.com'
  org.users << User.find_by(username: 'admin')

  org = Organization.new
  org.name = 'test'
  org.owner_email = 'test@example.com'
  org.users << User.find_by(username: 'test')
end

def update_super_admin
  user = User.find_by(username: 'admin')
  organization = user.organizations.find_by(name: 'cyclid')
  permissions = user.userpermissions.find_by(organization: organization)
  Cyclid.logger.debug permissions

  permissions.admin = true
  permissions.write = true
  permissions.read = true
  permissions.save!
end

create_users
create_organizations

update_super_admin
