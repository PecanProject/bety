class FixParentInDbFiles < ActiveRecord::Migration
  def self.up
    remove_column :dbfiles, :parent
    add_column :dbfiles, :parent_id, :integer
  end

  def self.down
    add_column :dbfiles, :parent, :integer
    remove_column :dbfiles, :parent_id
  end
end
