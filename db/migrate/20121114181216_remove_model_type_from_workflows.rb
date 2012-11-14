class RemoveModelTypeFromWorkflows < ActiveRecord::Migration
  def self.up
    remove_column :workflows, :model_type
  end

  def self.down
    add_column :workflows, :model_type
  end
end
