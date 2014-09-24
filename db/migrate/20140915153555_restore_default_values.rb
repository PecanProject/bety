class RestoreDefaultValues < ActiveRecord::Migration
  # This migration restores some default column values that were lost during the
  # migration form MySQL to PostgreSQL.  Although these defaults ARE set in the
  # file 001_create_database_objects.rb, it is currently impossible to run the
  # complete migration sequence to set the database structure without tweaking
  # some of the migration files.  Thus we make a new migration to ensure these
  # default values are set.
  def self.up
    change_column_default :traits, :checked, 0
    change_column_default :yields, :checked, 0
    change_column_default :users, :name, ""
  end

  def self.down
    change_column_default :traits, :checked, nil
    change_column_default :yields, :checked, nil
    change_column_default :users, :name, nil
  end
end
