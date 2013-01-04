class AddWorkflowIdToEnsembles < ActiveRecord::Migration
  def self.up
    add_column :ensembles, :workflow_id, :integer
  end

  def self.down
    remove_column :ensembles, :workflow_id
  end
end
