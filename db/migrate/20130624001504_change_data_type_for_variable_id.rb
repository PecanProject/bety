class ChangeDataTypeForVariableId < ActiveRecord::Migration
  def self.up
    change_table :priors do |t|
      t.change :variable_id, :integer
    end
  end

  def self.down
    change_table :priors do |t|
      t.change :variable_id, :string
    end
  end
end
