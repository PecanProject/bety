class ChangeUserIdToBigInt < ActiveRecord::Migration
  def self.up
    change_column :modeltypes, :user_id, :integer, :limit => 8
    change_column :modeltypes_formats, :user_id, :integer, :limit => 8
  end

  def self.down
    change_column :modeltypes, :user_id, :integer, :limit => 4
    change_column :modeltypes_formats, :user_id, :integer, :limit => 4
  end
end
