class PosteriorsTablesCleanup < ActiveRecord::Migration
  def self.up
  	drop_table :posteriors_runs

  	add_column :pfts, :pft_type, :string, default: "plant"
  	Pft.update_all pft_type: "plant"

    create_table :posterior_samples do |t|
      t.integer  :posterior_id, :limit => 8
      t.integer  :variable_id, :limit => 8
      t.integer  :pft_id, :limit => 8
      t.integer  :parent_id, :limit => 8
  	  t.datetime :created_at
  	  t.datetime :updated_at
    end

    create_table :projects do |t|
      t.string   :name
      t.string   :outdir
      t.integer  :machine_id, :limit => 8
      t.string   :description
  	  t.datetime :created_at
  	  t.datetime :updated_at
    end

    create_table :current_posteriors do |t|
      t.integer  :pft_id, :limit => 8
      t.integer  :variable_id, :limit => 8
      t.integer  :posteriors_samples_id, :limit => 8
      t.integer  :project_id, :limit => 8
  	  t.datetime :created_at
  	  t.datetime :updated_at
    end
  end

  def self.down
    create_table :posteriors_runs do |t|
      t.integer  :posterior_id, :limit => 8
      t.integer  :run_id, :limit => 8
  	  t.datetime :created_at
  	  t.datetime :updated_at
    end

  	remove_column :pfts, :pft_type

	drop_table :posterior_samples

	drop_table :projects

	drop_table :current_posteriors
  end
end
