class CreateAction < ActiveRecord::Migration
  def change
    create_table :actions do |t|
      t.integer :sequence, null: false
      t.text :action

      t.belongs_to :stage, index: true
    end
  end
end
