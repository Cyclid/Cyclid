class CreateUserPermissions < ActiveRecord::Migration
  def change
    create_table :userpermissions do |t|
      t.boolean :admin, null: false, default: false
      t.boolean :write, null: false, default: false
      t.boolean :read, null: false, default: false

      t.belongs_to :user, index: true
      t.belongs_to :organization, index:true
    end
  end
end
