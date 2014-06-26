class FixPosteriorsEnsembles < ActiveRecord::Migration
  def self.up
  	remove_column :posteriors_ensembles, :id
    change_column :posteriors_ensembles, :posterior_id, :integer, :limit => 8
    change_column :posteriors_ensembles, :ensemble_id, :integer, :limit => 8

    drop_table :posterior_samples
    create_table :posteriors_samples do |t|
      t.integer  :posterior_id, :limit => 8
      t.integer  :variable_id, :limit => 8
      t.integer  :pft_id, :limit => 8
      t.integer  :parent_id, :limit => 8
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
  	add_column :posteriors_ensembles, :id, :integer, :limit => 8
    change_column :posteriors_ensembles, :posterior_id, :integer, :limit => 4
    change_column :posteriors_ensembles, :ensemble_id, :integer, :limit => 4

    drop_table :posteriors_samples
    create_table :posterior_samples do |t|
      t.integer  :posterior_id, :limit => 8
      t.integer  :variable_id, :limit => 8
      t.integer  :pft_id, :limit => 8
      t.integer  :parent_id, :limit => 8
      t.datetime :created_at
      t.datetime :updated_at
    end
  end
end
