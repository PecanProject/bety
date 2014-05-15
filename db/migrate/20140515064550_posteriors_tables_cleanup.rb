class PosteriorsTablesCleanup < ActiveRecord::Migration
  def self.up
  	drop_table :posteriors_runs

  	add_column :pfts, :pft_type, :string, default: "plant"
  	Pft.update_all pft_type: "plant"

    create_table :posterior_samples do |t|
      t.integer  :posterior_id
      t.integer  :variable_id
      t.integer  :pft_id
      t.integer  :parent_id
  	  t.datetime :created_at
  	  t.datetime :updated_at
    end

    create_table :projects do |t|
      t.string   :name
      t.string   :outdir
      t.integer  :machine_id
      t.string   :description
  	  t.datetime :created_at
  	  t.datetime :updated_at
    end

    create_table :current_posteriors do |t|
      t.integer  :pft_id
      t.integer  :variable_id
      t.integer  :posteriors_samples_id
      t.integer  :project_id
  	  t.datetime :created_at
  	  t.datetime :updated_at
    end
  end

  def self.down
    create_table :posteriors_runs do |t|
      t.integer  :posterior_id
      t.integer  :run_id
  	  t.datetime :created_at
  	  t.datetime :updated_at
    end

  	remove_column :pfts, :type

	drop_table :posterior_samples

	drop_table :projects

	drop_table :current_posteriors
  end
end
