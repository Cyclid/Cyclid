class CreateUser < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username, null: false, unique: true
      t.string :email, null: false
      t.string :password
      t.string :secret
    end
  end
end
