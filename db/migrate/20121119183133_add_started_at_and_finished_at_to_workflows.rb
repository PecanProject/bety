class AddStartedAtAndFinishedAtToWorkflows < ActiveRecord::Migration
  def self.up
    add_column :workflows, :started_at, :datetime
    add_column :workflows, :finished_at, :datetime
  end

  def self.down
    remove_column :workflows, :started_at
    remove_column :workflows, :finished_at
  end
end
