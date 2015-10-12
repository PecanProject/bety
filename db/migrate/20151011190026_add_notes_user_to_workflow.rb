class AddNotesUserToWorkflow < ActiveRecord::Migration
  def up
    add_column :workflows, :notes, :text
    add_column :workflows, :user_id, :integer, :limit => 8
  end
 
  def down
    remove_column :workflows, :notes
    remove_column :workflows, :user_id
  end
end
