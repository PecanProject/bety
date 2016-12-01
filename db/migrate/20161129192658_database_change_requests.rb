class DatabaseChangeRequests < ActiveRecord::Migration
  def up
    change_column :likelihoods, :loglikelihood, :float
    change_column :likelihoods, :n_eff, :float
    change_column :likelihoods, :weight, :float
    change_column :likelihoods, :residual, :float

    execute %q{
        ALTER TABLE likelihoods
            DROP CONSTRAINT unique_run_variable_input_combination
    }
  end

  def down
    change_column :likelihoods, :loglikelihood, :decimal, precision: 10, scale: 0
    change_column :likelihoods, :n_eff, :decimal, precision: 10, scale: 0
    change_column :likelihoods, :weight, :decimal, precision: 10, scale: 0
    change_column :likelihoods, :residual, :decimal, precision: 10, scale: 0

    execute %q{
        ALTER TABLE likelihoods
            ADD CONSTRAINT unique_run_variable_input_combination
                UNIQUE (run_id, variable_id, input_id)
    }
  end
end
