class RemoveDataformatFromFormats < ActiveRecord::Migration
  def up
    remove_column :formats, :dataformat
  end
  def down
    add_column :formats, :dataformat, :text, default: "", null: false
  end
end
