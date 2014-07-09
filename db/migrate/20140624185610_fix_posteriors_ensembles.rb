class FixPosteriorsEnsembles < ActiveRecord::Migration
  def self.up
  	remove_column :posteriors_ensembles, :id
    change_column :posteriors_ensembles, :posterior_id, :integer, :limit => 8
    change_column :posteriors_ensembles, :ensemble_id, :integer, :limit => 8
  end

  def self.down
  	add_column :posteriors_ensembles, :id, :integer, :limit => 8
    change_column :posteriors_ensembles, :posterior_id, :integer, :limit => 4
    change_column :posteriors_ensembles, :ensemble_id, :integer, :limit => 4
  end
end
