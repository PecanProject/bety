class AddFieldsToVariables < ActiveRecord::Migration
  def self.up
  	add_column :variables, :standard_name, :string
  	add_column :variables, :standard_units, :string
  	add_column :variables, :label, :string
  	add_column :variables, :type, :string

  end

  def self.down
  	remove_column :variables, :type
  	remove_column :variables, :label
  	remove_column :variables, :standard_units
  	remove_column :variables, :standard_name
  end
end
