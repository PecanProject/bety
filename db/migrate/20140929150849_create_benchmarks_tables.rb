class CreateBenchmarksTables < ActiveRecord::Migration
  def self.up
    # Create the table as normal, then change id to bigint, so all
    # pieces are created, like index and auto increment. This is
    # done for all tables with an :id

    create_table :benchmarks do |t|
      t.integer :input_id, :limit => 8, :null => false
      t.text    :description
      t.integer :site_id, :limit => 8, :null => false
      t.integer :variable_id, :limit => 8, :null => false
      t.integer :user_id, :limit => 8
      t.datetime :created_at
      t.datetime :updated_at
    end
    change_column :benchmarks, :id, :integer, :limit => 8

    create_table :metrics do |t|
      t.string :name
      t.text :description 
      t.integer :citation_id, :limit => 8
      t.integer :user_id, :limit => 8
      t.datetime :created_at
      t.datetime :updated_at
    end
    change_column :metrics, :id, :integer, :limit => 8

    create_table :benchmarks_ensembles do |t|
      t.integer :ref_id, :limit => 8, :null => false
      t.integer :ensemble_id, :limit => 8, :null => false
      t.integer :model_id, :limit => 8, :null => false
      t.integer :citation_id, :limit => 8, :null => false
      t.integer :user_id, :limit => 8
      t.datetime :created_at
      t.datetime :updated_at
    end
    change_column :benchmarks_ensembles, :id, :integer, :limit => 8

    create_table :benchmarks_ensembles_scores do |t|
      t.integer :benchmarks_ensembles_id, :limit => 8, :null => false
      t.integer :benchmark_id, :limit => 8, :null => false
      t.integer :metric_id, :limit => 8, :null => false
      t.integer :user_id, :limit => 8
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :benchmarks_ref_runs do |t|
      t.integer :model_id, :limit => 8 
      t.text :settings 
      t.integer :user_id, :limit => 8
      t.datetime :created_at
      t.datetime :updated_at
    end
    change_column :benchmarks_ref_runs, :id, :integer, :limit => 8

    create_table :benchmarks_metrics, :id => false do |t|
      t.integer :benchmark_id, :limit => 8
      t.integer :metric_id, :limit => 8
    end

    create_table :benchmarks_brr, :id => false do |t|
      t.integer :benchmark_id, :limit => 8
      t.integer :ref_id, :limit => 8
    end
  end

  def self.down
    drop_table :benchmarks
    drop_table :metrics
    drop_table :benchmarks_ensembles
    drop_table :benchmarks_metrics
    drop_table :benchmarks_ref_runs
    drop_table :benchmarks_brr
    drop_table :benchmarks_ensembles_scores
  end
end
