class AddPosteriorsEnsembles < ActiveRecord::Migration
  def self.up
	create_table :posteriors_ensembles do |t|
		t.integer :posterior_id
		t.integer :ensemble_id
		t.timestamps
	end
  end

  def self.down
	drop_table :posteriors_ensembles
  end
end
