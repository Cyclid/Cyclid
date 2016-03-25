#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path('../../lib', __FILE__)

require 'require_all'
require 'logger'
require 'active_record'

ENV['RACK_ENV'] = ENV['RACK_ENV'] || 'development'

module Cyclid
  class << self
    attr_accessor :logger

    begin
      Cyclid.logger = Logger.new(STDERR)
    rescue StandardError => ex
      abort "Failed to initialize: #{ex}"
    end
  end
end

require 'db'
require 'cyclid/models'

include Cyclid::API

ADMINS_ORG = 'admins'.freeze
RSA_KEY_LENGTH = 2048

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
  key = OpenSSL::PKey::RSA.new(RSA_KEY_LENGTH)

  org = Organization.new
  org.name = ADMINS_ORG
  org.owner_email = 'admins@example.com'
  org.rsa_private_key = key.to_der
  org.rsa_public_key = key.public_key.to_der
  org.salt = SecureRandom.hex(32)
  org.users << User.find_by(username: 'admin')

  key = OpenSSL::PKey::RSA.new(RSA_KEY_LENGTH)

  org = Organization.new
  org.name = 'test'
  org.owner_email = 'test@example.com'
  org.rsa_private_key = key.to_der
  org.rsa_public_key = key.public_key.to_der
  org.salt = SecureRandom.hex(32)
  org.users << User.find_by(username: 'test')
end

def update_user_perms
  # 'admin' user is a Super Admin
  user = User.find_by(username: 'admin')
  organization = user.organizations.find_by(name: ADMINS_ORG)
  permissions = user.userpermissions.find_by(organization: organization)
  Cyclid.logger.debug permissions

  permissions.admin = true
  permissions.write = true
  permissions.read = true
  permissions.save!

  # 'test' user is an admin for the 'test' org
  user = User.find_by(username: 'test')
  organization = user.organizations.find_by(name: 'test')
  permissions = user.userpermissions.find_by(organization: organization)
  Cyclid.logger.debug permissions

  permissions.admin = true
  permissions.write = true
  permissions.read = true
  permissions.save!
end

create_users
create_organizations

update_user_perms
