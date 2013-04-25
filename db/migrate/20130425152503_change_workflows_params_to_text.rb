class ChangeWorkflowsParamsToText < ActiveRecord::Migration
  def self.up
  	change_column :workflows, :params, :text
  end

  def self.down
  	change_column :workflows, :params, :string
  end
end
