class AddScoreBenchmarksEnsemblesScores < ActiveRecord::Migration
  def up
    add_column :benchmarks_ensembles_scores, :score, :text,  :null => false
  end

  def down
    remove_column :benchmarks_ensembles_scores, :score
  end
end
