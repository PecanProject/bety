class UpdatePosteriors < ActiveRecord::Migration
  def self.up
    add_column :posteriors, :format_id, :integer
    remove_column :posteriors, :filename
    remove_column :posteriors, :parent_id
  end

  def self.down
    remove_column :posteriors, :format_id
    add_column :posteriors, :filename, :string
    add_column :posteriors, :parent_id, :integer
  end
end
