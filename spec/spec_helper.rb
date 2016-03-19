require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/test/'
  add_filter '/db/'
end

# Pull in dependencies and Rack mocks
require 'active_record'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

# Required by the Rack mocks
def app
  Cyclid::API::App
end

# Pull in the code
require_relative '../lib/cyclid'

# Helper to create an empty database
def setup_database
  ActiveRecord::Base.remove_connection

  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: ':memory:'
  )
  load File.expand_path('db/schema.rb')
end

# Helpers for setting up a single admin user & admins organization
ADMINS_ORG = 'admins'.freeze

def create_admin_user
  user = Cyclid::API::User.new
  user.username = 'admin'
  user.email = 'admin@example.com'
  user.secret = 'aasecret55'
  user.new_password = 'password'
  user.save!
end

def create_admin_organization
  org = Cyclid::API::Organization.new
  org.name = ADMINS_ORG
  org.owner_email = 'admins@example.com'
  org.users << Cyclid::API::User.find_by(username: 'admin')
end

def update_admin_user_perms
  user = Cyclid::API::User.find_by(username: 'admin')
  organization = user.organizations.find_by(name: ADMINS_ORG)
  permissions = user.userpermissions.find_by(organization: organization)

  permissions.admin = true
  permissions.write = true
  permissions.read = true
  permissions.save!
end

# Some top level helpers to make things easier
def setup_admin
  create_admin_user
  create_admin_organization
  update_admin_user_perms
end

def new_database
  setup_database
  setup_admin
end

# Rack Mock wrappers
def post_json(endpoint, json)
  post(endpoint, json, 'CONTENT_TYPE' => 'text/json')
end

def post_yaml(endpoint, yaml)
  post(endpoint, yaml, 'CONTENT_TYPE' => 'text/x-yaml')
end

def put_json(endpoint, json)
  put(endpoint, json, 'CONTENT_TYPE' => 'text/json')
end
