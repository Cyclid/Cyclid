# frozen_string_literal: true
require 'spec_helper'

describe 'authentication strategies' do
  include Rack::Test::Methods

  before :all do
    new_database

    # Create an admin (but non-Super Admin) user
    new_user = { 'username' => 'orgadmin',
                 'email' => 'orgadmin@example.com',
                 'new_password' => 'password' }

    authorize 'admin', 'password'
    post_json '/users', new_user.to_json

    # Create a non-admin user
    new_user = { 'username' => 'nonadmin',
                 'email' => 'nonadmin@example.com',
                 'new_password' => 'password' }

    authorize 'admin', 'password'
    post_json '/users', new_user.to_json

    # Create a read-only user
    new_user = { 'username' => 'readonly',
                 'email' => 'readonly@example.com',
                 'new_password' => 'password' }

    authorize 'admin', 'password'
    post_json '/users', new_user.to_json

    # Create a user with no permissions
    new_user = { 'username' => 'nobody',
                 'email' => 'nobody@example.com',
                 'new_password' => 'password' }

    authorize 'admin', 'password'
    post_json '/users', new_user.to_json

    # Create an organization with all of those users as members
    new_org = { 'name' => 'test',
                'users' => %w(orgadmin nonadmin readonly nobody),
                'owner_email' => 'admin@example.com' }

    authorize 'admin', 'password'
    post_json '/organizations', new_org.to_json

    # Set each users permissions appropriately
    new_perms = { permissions: { admin: true, write: true, read: true } }

    authorize 'admin', 'password'
    put_json '/organizations/test/members/orgadmin', new_perms.to_json

    new_perms = { permissions: { admin: false, write: true, read: true } }

    authorize 'admin', 'password'
    put_json '/organizations/test/members/nonadmin', new_perms.to_json

    new_perms = { permissions: { admin: false, write: false, read: true } }

    authorize 'admin', 'password'
    put_json '/organizations/test/members/readonly', new_perms.to_json

    new_perms = { permissions: { admin: false, write: false, read: false } }

    authorize 'admin', 'password'
    put_json '/organizations/test/members/nobody', new_perms.to_json

    # Create a user who is not a member of the test organization
    new_user = { 'username' => 'nonmember',
                 'email' => 'nonmember@example.com',
                 'new_password' => 'password' }

    authorize 'admin', 'password'
    post_json '/users', new_user.to_json
  end

  context 'authorized_for' do
    context 'with an admin user' do
      it 'is authorized for ADMIN operations' do
        new_stage = { name: 'test1', steps: [] }

        authorize 'orgadmin', 'password'
        post_json '/organizations/test/stages', new_stage.to_json
        expect(last_response.status).to eq(200)
      end

      it 'is authorized for WRITE operations' do
        modified_org = { 'owner_email' => 'test@example.com' }

        authorize 'orgadmin', 'password'
        put_json '/organizations/test', modified_org.to_json
        expect(last_response.status).to eq(200)
      end

      it 'is authorized for READ operations' do
        authorize 'orgadmin', 'password'
        get '/organizations/test'
        expect(last_response.status).to eq(200)
      end
    end

    context 'with a non-admin user' do
      it 'is not authorized for ADMIN operations' do
        new_stage = { name: 'test2', steps: [] }

        authorize 'nonadmin', 'password'
        post_json '/organizations/test/stages', new_stage.to_json
        expect(last_response.status).to eq(401)
      end

      it 'is authorized for WRITE operations' do
        modified_org = { 'owner_email' => 'test@example.com' }

        authorize 'nonadmin', 'password'
        put_json '/organizations/test', modified_org.to_json
        expect(last_response.status).to eq(200)
      end

      it 'is authorized for READ operations' do
        authorize 'nonadmin', 'password'
        get '/organizations/test'
        expect(last_response.status).to eq(200)
      end
    end

    context 'with a read-only user' do
      it 'is not authorized for ADMIN operations' do
        new_stage = { name: 'test3', steps: [] }

        authorize 'readonly', 'password'
        post_json '/organizations/test/stages', new_stage.to_json
        expect(last_response.status).to eq(401)
      end

      it 'is not authorized for WRITE operations' do
        modified_org = { 'owner_email' => 'test@example.com' }

        authorize 'readonly', 'password'
        put_json '/organizations/test', modified_org.to_json
        expect(last_response.status).to eq(401)
      end

      it 'is authorized for READ operations' do
        authorize 'readonly', 'password'
        get '/organizations/test'
        expect(last_response.status).to eq(200)
      end
    end

    context 'with a user with no permissions' do
      it 'is not authorized for ADMIN operations' do
        new_stage = { name: 'test4', steps: [] }

        authorize 'nobody', 'password'
        post_json '/organizations/test/stages', new_stage.to_json
        expect(last_response.status).to eq(401)
      end

      it 'is not authorized for WRITE operations' do
        modified_org = { 'owner_email' => 'test@example.com' }

        authorize 'nobody', 'password'
        put_json '/organizations/test', modified_org.to_json
        expect(last_response.status).to eq(401)
      end

      it 'is not authorized for READ operations' do
        authorize 'nobody', 'password'
        get '/organizations/test'
        expect(last_response.status).to eq(401)
      end
    end

    context 'with a user who is not an organization member' do
      it 'is not authorized' do
        authorize 'nonmember', 'password'
        get '/organizations/test'
        expect(last_response.status).to eq(401)
      end
    end
  end

  context 'authorized_as' do
    before :all do
      # Create an 'admin' super-admin
      new_user = { 'username' => 'super',
                   'email' => 'super@example.com',
                   'new_password' => 'password' }

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json

      # Create a 'write' super-admin
      new_user = { 'username' => 'write',
                   'email' => 'write@example.com',
                   'new_password' => 'password' }

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json

      # Create a 'read' super-admin
      new_user = { 'username' => 'read',
                   'email' => 'read@example.com',
                   'new_password' => 'password' }

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json

      # Create a 'nothing' super-admin
      new_user = { 'username' => 'nothing',
                   'email' => 'nothing@example.com',
                   'new_password' => 'password' }

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json

      # Add the new users to the 'admins' group
      modified_org = { 'users' => %w(admin super write read nothing) }

      authorize 'admin', 'password'
      put_json '/organizations/admins', modified_org.to_json

      # Set the appropriate permissions for each user
      new_perms = { permissions: { admin: true, write: true, read: true } }

      authorize 'admin', 'password'
      put_json '/organizations/admins/members/super', new_perms.to_json

      new_perms = { permissions: { admin: false, write: true, read: true } }

      authorize 'admin', 'password'
      put_json '/organizations/admins/members/write', new_perms.to_json

      new_perms = { permissions: { admin: false, write: false, read: true } }

      authorize 'admin', 'password'
      put_json '/organizations/admins/members/read', new_perms.to_json

      new_perms = { permissions: { admin: false, write: false, read: false } }

      authorize 'admin', 'password'
      put_json '/organizations/admins/members/nothing', new_perms.to_json
    end

    before :each do
      # Create a user to manipulate
      new_user = { 'username' => 'test',
                   'email' => 'test@example.com',
                   'new_password' => 'password' }

      authorize 'admin', 'password'
      post_json '/users', new_user.to_json
    end

    context 'with a super admin user' do
      it 'is authorized for ADMIN operations' do
        authorize 'super', 'password'
        delete '/users/test'
        expect(last_response.status).to eq(200)
      end

      it 'is authorized for WRITE operations' do
        modified_user = { 'email' => 'test_user@example.com' }

        authorize 'super', 'password'
        put_json '/users/test', modified_user.to_json
        expect(last_response.status).to eq(200)
      end

      it 'is authorized for READ operations' do
        authorize 'super', 'password'
        get '/users/test'
        expect(last_response.status).to eq(200)
      end
    end

    context 'with a non-admin user' do
      it 'is not authorized for ADMIN operations' do
        authorize 'write', 'password'
        delete '/users/test'
        expect(last_response.status).to eq(401)
      end

      it 'is authorized for WRITE operations' do
        modified_user = { 'email' => 'test_user@example.com' }

        authorize 'write', 'password'
        put_json '/users/test', modified_user.to_json
        expect(last_response.status).to eq(200)
      end

      it 'is authorized for READ operations' do
        authorize 'write', 'password'
        get '/users/test'
        expect(last_response.status).to eq(200)
      end
    end

    context 'with a read-only user' do
      it 'is not authorized for ADMIN operations' do
        authorize 'read', 'password'
        delete '/users/test'
        expect(last_response.status).to eq(401)
      end

      it 'is not authorized for WRITE operations' do
        modified_user = { 'email' => 'test_user@example.com' }

        authorize 'read', 'password'
        put_json '/users/test', modified_user.to_json
        expect(last_response.status).to eq(401)
      end

      it 'is authorized for READ operations' do
        authorize 'read', 'password'
        get '/users/test'
        expect(last_response.status).to eq(200)
      end
    end

    context 'with a user with no permissions' do
      it 'is not authorized for ADMIN operations' do
        authorize 'nothing', 'password'
        delete '/users/test'
        expect(last_response.status).to eq(401)
      end

      it 'is not authorized for WRITE operations' do
        modified_user = { 'email' => 'test_user@example.com' }

        authorize 'nothing', 'password'
        put_json '/users/test', modified_user.to_json
        expect(last_response.status).to eq(401)
      end

      it 'is not authorized for READ operations' do
        authorize 'nothing', 'password'
        get '/users/test'
        expect(last_response.status).to eq(401)
      end
    end
  end
end
