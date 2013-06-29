class ChangeRevisionToString < ActiveRecord::Migration
  def self.up
        change_column :models, :revision, :string
  end

  def self.down
	raise ActiveRecord::IrreversibleMigration
  end
end
