class ChangeIntToDecimalInSite < ActiveRecord::Migration
  def self.up
  	change_column :sites, :mat, :decimal, :precision => 4, :scale => 2
  end

  def self.down
  	change_column :sites, :mat, :integer
  end
end
