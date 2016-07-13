class CreateBenchmarksTables < ActiveRecord::Migration
  def self.up
    this_hostid = Machine.new.hostid

    # Create the table as normal, then change id to bigint, so all
    # pieces are created, like index and auto increment. Also all
    # id's will be set to auto-increment based on the host.

    create_table :benchmarks do |t|
      t.integer :id, :limit => 8
      t.integer :input_id, :limit => 8, :null => false
      t.text    :description
      t.integer :site_id, :limit => 8, :null => false
      t.integer :variable_id, :limit => 8, :null => false
      t.integer :user_id, :limit => 8

      t.timestamps
    end
    execute %{
      SELECT setval('benchmarks_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
      ALTER TABLE "benchmarks"
      ALTER COLUMN created_at SET DEFAULT utc_now(),
      ALTER COLUMN updated_at SET DEFAULT utc_now();
      ALTER TABLE "benchmarks"
      ADD CONSTRAINT "benchmarks_input_id_fkey" 
        FOREIGN KEY ("input_id") REFERENCES inputs("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
      ADD CONSTRAINT "benchmarks_site_id_fkey" 
        FOREIGN KEY ("site_id") REFERENCES sites("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
      ADD CONSTRAINT "benchmarks_variable_id_fkey" 
        FOREIGN KEY ("variable_id") REFERENCES variables("id")
        ON DELETE RESTRICT ON UPDATE CASCADE;
    }

    create_table :metrics do |t|
      t.integer :id, :limit => 8
      t.string :name
      t.text :description 
      t.integer :citation_id, :limit => 8
      t.integer :user_id, :limit => 8

      t.timestamps
    end
    execute %{
      SELECT setval('metrics_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
      ALTER TABLE "metrics"
      ALTER COLUMN created_at SET DEFAULT utc_now(),
      ALTER COLUMN updated_at SET DEFAULT utc_now();
    }

    create_table :reference_runs do |t|
      t.integer :id, :limit => 8
      t.integer :model_id, :limit => 8 
      t.text :settings 
      t.integer :user_id, :limit => 8

      t.timestamps
    end
    execute %{
      SELECT setval('reference_runs_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
      ALTER TABLE "reference_runs"
      ALTER COLUMN created_at SET DEFAULT utc_now(),
      ALTER COLUMN updated_at SET DEFAULT utc_now();
      ALTER TABLE "reference_runs"
      ADD CONSTRAINT "reference_runs_model_id_fkey" 
        FOREIGN KEY ("model_id") REFERENCES models("id")
        ON DELETE RESTRICT ON UPDATE CASCADE;
    }

    create_table :benchmark_sets do |t|
      t.integer :id, :limit => 8
      t.string :name, :null => false
      t.text :description
      t.integer :user_id, :limit => 8

      t.timestamps
    end
    execute %{
      SELECT setval('benchmark_sets_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
      ALTER TABLE "benchmark_sets"
      ALTER COLUMN created_at SET DEFAULT utc_now(),
      ALTER COLUMN updated_at SET DEFAULT utc_now();
    }

    create_table :benchmarks_ensembles do |t|
      t.integer :id, :limit => 8
      t.integer :reference_run_id, :limit => 8, :null => false
      t.integer :ensemble_id, :limit => 8, :null => false
      t.integer :model_id, :limit => 8, :null => false
      t.integer :citation_id, :limit => 8, :null => false
      t.integer :user_id, :limit => 8

      t.timestamps
    end
    execute %{
      SELECT setval('benchmarks_ensembles_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
      ALTER TABLE "benchmarks_ensembles"
      ALTER COLUMN created_at SET DEFAULT utc_now(),
      ALTER COLUMN updated_at SET DEFAULT utc_now();
      ALTER TABLE "benchmarks_ensembles"
      ADD CONSTRAINT "benchmarks_ensembles_ensemble_id_fkey" 
        FOREIGN KEY ("ensemble_id") REFERENCES ensembles("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
      ADD CONSTRAINT "benchmarks_ensembles_model_id_fkey" 
        FOREIGN KEY ("model_id") REFERENCES models("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
      ADD CONSTRAINT "benchmarks_ensembles_reference_run_id_fkey" 
        FOREIGN KEY ("reference_run_id") REFERENCES reference_runs("id") 
        ON DELETE RESTRICT ON UPDATE CASCADE;
    }

    create_table :benchmarks_ensembles_scores do |t|
      t.integer :id, :limit => 8
      t.integer :benchmarks_ensemble_id, :limit => 8, :null => false
      t.integer :benchmark_id, :limit => 8, :null => false
      t.integer :metric_id, :limit => 8, :null => false
      t.integer :user_id, :limit => 8

      t.timestamps
    end
    execute %{
      SELECT setval('benchmarks_ensembles_scores_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
      ALTER TABLE "benchmarks_ensembles_scores"
      ALTER COLUMN created_at SET DEFAULT utc_now(),
      ALTER COLUMN updated_at SET DEFAULT utc_now();
      ALTER TABLE "benchmarks_ensembles_scores"
      ADD CONSTRAINT "benchmarks_ensembles_scores_benchmark_id_fkey" 
        FOREIGN KEY ("benchmark_id") REFERENCES benchmarks("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
      ADD CONSTRAINT "benchmarks_ensembles_scores_benchmarks_ensemble_id_fkey" 
        FOREIGN KEY ("benchmarks_ensemble_id") REFERENCES benchmarks_ensembles("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
      ADD CONSTRAINT "benchmarks_ensembles_scores_metric_id_fkey" 
        FOREIGN KEY ("metric_id") REFERENCES metrics("id")
        ON DELETE RESTRICT ON UPDATE CASCADE;
    }

    create_table :benchmarks_metrics do |t|
      t.integer :id, :limit => 8
      t.integer :benchmark_id, :limit => 8
      t.integer :metric_id, :limit => 8
    end
    execute %{
      SELECT setval('benchmarks_metrics_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
      ALTER TABLE "benchmarks_metrics"
      ADD CONSTRAINT "benchmarks_metrics_benchmark_id_fkey" 
        FOREIGN KEY ("benchmark_id") REFERENCES benchmarks("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
      ADD CONSTRAINT "benchmarks_metrics_metric_id_fkey" 
        FOREIGN KEY ("metric_id") REFERENCES metrics("id")
        ON DELETE RESTRICT ON UPDATE CASCADE;
    }

    create_table :benchmarks_benchmarks_reference_runs do |t|
      t.integer :id, :limit => 8
      t.integer :benchmark_id, :limit => 8
      t.integer :reference_run_id, :limit => 8
    end
    execute %{
      SELECT setval('benchmarks_benchmarks_reference_runs_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
      ALTER TABLE "benchmarks_benchmarks_reference_runs"
      ADD CONSTRAINT "benchmarks_benchmarks_reference_runs_benchmark_id_fkey" 
        FOREIGN KEY ("benchmark_id") REFERENCES benchmarks("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
      ADD CONSTRAINT "benchmarks_benchmarks_reference_runs_reference_run_id_fkey" 
        FOREIGN KEY ("reference_run_id") REFERENCES reference_runs("id")
        ON DELETE RESTRICT ON UPDATE CASCADE;
    }

    create_table :benchmark_sets_benchmark_reference_runs do |t|
      t.integer :id, :limit => 8
      t.integer :benchmark_set_id, :limit => 8
      t.integer :reference_run_id, :limit => 8
    end  
    execute %{
      SELECT setval('benchmark_sets_benchmark_reference_runs_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
      ALTER TABLE "benchmark_sets_benchmark_reference_runs"
      ADD CONSTRAINT "benchmark_sets_benchmark_reference_runs_benchmark_set_id_fkey" 
        FOREIGN KEY ("benchmark_set_id") REFERENCES benchmark_sets("id")
        ON DELETE RESTRICT ON UPDATE CASCADE,
      ADD CONSTRAINT "benchmark_sets_benchmark_reference_runs_reference_run_id_fkey" 
        FOREIGN KEY ("reference_run_id") REFERENCES reference_runs("id")
        ON DELETE RESTRICT ON UPDATE CASCADE;
    }
  end

  def self.down
    drop_table :benchmark_sets_benchmark_reference_runs
    drop_table :benchmarks_benchmarks_reference_runs
    drop_table :benchmarks_metrics
    drop_table :benchmarks_ensembles_scores
    drop_table :benchmarks_ensembles
    drop_table :benchmark_sets
    drop_table :reference_runs
    drop_table :metrics
    drop_table :benchmarks
  end
end
