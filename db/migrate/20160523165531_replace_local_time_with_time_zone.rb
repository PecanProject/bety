class ReplaceLocalTimeWithTimeZone < ActiveRecord::Migration
  def up
    add_column :sites, :time_zone, :text
    remove_column :sites, :local_time
  end

  def down
    add_column :sites, :local_time, :integer
    remove_column :sites, :time_zone
  end
end
