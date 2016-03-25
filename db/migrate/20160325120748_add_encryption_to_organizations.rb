class AddEncryptionToOrganizations < ActiveRecord::Migration
  def change
    # RSA keys in DER format
    add_column :organizations, :rsa_private_key, :binary, null: false, default: 0
    add_column :organizations, :rsa_public_key, :binary, null: false, default: 0

    # Salt for use with other encryption schemes E.g. AES
    add_column :organizations, :salt, :string, null: false, default: 0
  end
end
