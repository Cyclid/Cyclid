class CreateStage < ActiveRecord::Migration
  def change
    create_table :stages do |t|
      t.string :name, null: false
      t.string :version, null: false, default: '0.0.1'

      t.belongs_to :organization, index: true
    end
  end
end
