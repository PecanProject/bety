# RAILS3 Fields named "field" are not allowed in Rails 3
class RenameUserFieldField < ActiveRecord::Migration
  def self.up
    rename_column :users, :field, :area
  end

  def self.down
    rename_column :users, :area, :field
  end
end
