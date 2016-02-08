class CreateOrganization < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name, null: false, unique: true
      t.string :owner_email, null: false
    end
  end
end
