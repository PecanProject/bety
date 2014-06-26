class RemoveInputsFileId < ActiveRecord::Migration
  def self.up
    remove_column :inputs, :file_id
  end

  def self.down
    add_column :inputs, :file_id, :integer
  end
end
