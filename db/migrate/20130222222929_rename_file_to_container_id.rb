class RenameFileToContainerId < ActiveRecord::Migration
  def self.up
    rename_column :dbfiles, :file_id, :container_id
  end

  def self.down
    rename_column :dbfiles, :container_id, :file_id
  end
end
