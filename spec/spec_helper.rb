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

# Configure RSpec
RSpec::Expectations.configuration.warn_about_potential_false_positives = false

# Mock external HTTP requests
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

# Pull in dependencies and Rack mocks
require 'active_record'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

# Required by the Rack mocks
def app
  Cyclid::API::App
end

# Pull in the code
require_relative '../app/cyclid'

# Turn down log output
Cyclid.logger.level = Logger::FATAL

# Helper to create an empty database
def setup_database
  ActiveRecord::Base.remove_connection

  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: ':memory:'
  )

  ActiveRecord::Migration.suppress_messages do
    load File.expand_path('db/schema.rb')
  end
end

# Helpers for setting up a single admin user & admins organization
ADMINS_ORG = 'admins'.freeze

def create_admin_user
  user = Cyclid::API::User.new
  user.username = 'admin'
  user.email = 'admin@example.com'
  user.name = 'Admin Test'
  user.secret = 'aasecret55'
  user.new_password = 'password'
  user.save!
end

def create_admin_organization
  key = OpenSSL::PKey::RSA.new(2048)

  org = Cyclid::API::Organization.new
  org.name = ADMINS_ORG
  org.owner_email = 'admins@example.com'
  org.rsa_private_key = key.to_der
  org.rsa_public_key = key.public_key.to_der
  org.salt = SecureRandom.hex(32)
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
