class CreateJobRecord < ActiveRecord::Migration
  def change
    create_table :job_records do |t|
      t.string :job_name, index: true
      t.string :job_version

      t.datetime :started
      t.datetime :ended

      t.integer :status
      t.text :log

      t.text :job

      t.belongs_to :organization, index: true
      t.belongs_to :user, index: true
    end
  end
end
