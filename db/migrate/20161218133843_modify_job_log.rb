require 'active_support/core_ext/numeric'

class ModifyJobLog < ActiveRecord::Migration
  def up
    change_column(:job_records, :log, :text, limit: 16.megabytes - 1)
  end
end
