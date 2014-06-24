class UpdateIdsToBigIntPosteriosEnsembles < ActiveRecord::Migration
  def self.up
    change_column :posteriors_ensembles, :posterior_id, :integer, :limit => 8
    change_column :posteriors_ensembles, :ensemble_id, :integer, :limit => 8
  end

  def self.down
    change_column :posteriors_ensembles, :posterior_id, :integer, :limit => 4
    change_column :posteriors_ensembles, :ensemble_id, :integer, :limit => 4
  end
end
