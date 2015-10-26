class AddNotesUserToWorkflow < ActiveRecord::Migration
  def up
    add_column :workflows, :notes, :text
    add_column :workflows, :user_id, :integer, :limit => 8

	execute %{
ALTER TABLE "workflows" ADD CONSTRAINT "fk_workflows_users_1" FOREIGN KEY ("user_id") REFERENCES "users" ("id");
}
  end

  def down
    remove_column :workflows, :notes
    remove_column :workflows, :user_id
  end
end
