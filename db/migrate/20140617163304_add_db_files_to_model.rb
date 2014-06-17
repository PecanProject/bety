class AddDbFilesToModel < ActiveRecord::Migration
  def self.up
    remove_column :models, :model_path

    execute "DELETE FROM models WHERE id NOT IN (SELECT MIN(id) FROM models GROUP BY model_name, revision)"
  end

  def self.down
    add_column :models, :model_path, :string
  end
end
