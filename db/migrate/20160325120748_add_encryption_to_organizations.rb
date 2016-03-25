class AddEncryptionToOrganizations < ActiveRecord::Migration
  def change
    # RSA keys in DER format
    add_column :organizations, :rsa_private_key, :binary
    add_column :organizations, :rsa_public_key, :binary

    # Salt for use with other encryption schemes E.g. AES
    add_column :organizations, :salt, :string
  end
end
