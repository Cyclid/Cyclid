# Top level module for all of the core Cyclid code.
module Cyclid
  # Module for the Cyclid API
  module API
    # Module for all Organization related API endpoints
    module Organizations
      # API endpoints for Organization members
      module Members
        def self.registered(app)
          include Errors::HTTPErrors

          # @method get_organizations_organization_members_member
          # @param [String] name Name of the organization.
          # @param [String] username Username of the member.
          # @return [String] JSON represention of the requested member.
          # Get the details of the specified user within the organization.
          app.get '/:username' do
            authorized_for!(params[:name], Operations::READ)

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            user = org.users.find_by(username: params[:username])
            halt_with_json_response(404, INVALID_USER, 'user does not exist') \
              if user.nil?

            begin
              perms = user.userpermissions.find_by(organization: org)

              user_hash = user.serializable_hash
              user_hash.delete_if do |key, _value|
                key == 'password' || key == 'secret'
              end

              perms_hash = perms.serializable_hash
              perms_hash.delete_if do |key, _value|
                key == 'id' || key == 'user_id' || key == 'organization_id'
              end

              user_hash['permissions'] = perms_hash

              return user_hash.to_json
            rescue ActiveRecord::ActiveRecordError, \
                   ActiveRecord::UnknownAttributeError => ex

              Cyclid.logger.debug ex.message
              halt_with_json_response(500, INTERNAL_ERROR, ex.message)
            end
          end

          # @method put("/organizations/:name/members/:username")
          # @param [String] name Name of the organization.
          # @param [String] username Username of the member.
          # Modify the specified user within the organization.
          app.put '/:username' do
            authorized_for!(params[:name], Operations::WRITE)

            payload = json_request_body
            Cyclid.logger.debug payload

            org = Organization.find_by(name: params[:name])
            halt_with_json_response(404, INVALID_ORG, 'organization does not exist') \
              if org.nil?

            user = org.users.find_by(username: params[:username])
            halt_with_json_response(404, INVALID_USER, 'user does not exist') \
              if user.nil?

            begin
              perms = user.userpermissions.find_by(organization: org)

              payload_perms = payload['permissions'] if payload.key? 'permissions'
              unless payload_perms.nil?
                perms.admin = payload_perms['admin'] if payload_perms.key? 'admin'
                perms.write = payload_perms['write'] if payload_perms.key? 'write'
                perms.read = payload_perms['read'] if payload_perms.key? 'read'

                Cyclid.logger.debug perms.serializable_hash

                perms.save!
              end
            rescue ActiveRecord::ActiveRecordError, \
                   ActiveRecord::UnknownAttributeError => ex

              Cyclid.logger.debug ex.message
              halt_with_json_response(500, INTERNAL_ERROR, ex.message)
            end
          end
        end
      end
    end
  end
end
