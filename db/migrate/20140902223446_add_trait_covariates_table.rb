class AddTraitCovariatesTable < ActiveRecord::Migration
  def self.up
    create_table :trait_covariate_associations, :id => false do |t|
      t.integer :trait_variable_id, :limit => 8, :null => false
      t.integer :covariate_variable_id, :limit => 8, :null => false
      t.boolean :required
    end
    add_index :trait_covariate_associations, [:trait_variable_id, :covariate_variable_id], :unique =>true, :name => :trait_covariate_associations_uniqueness
  end

  def self.down
    drop_table :trait_covariate_associations
  end
end
