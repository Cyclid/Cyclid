class CreatePluginConfig < ActiveRecord::Migration
  def change
    create_table :plugin_configs do |t|
      t.string :plugin
      t.string :version

      t.text :config

      t.belongs_to :organization, index: true
    end
  end
end
