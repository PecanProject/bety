class SitesCultivarsUniqueness < ActiveRecord::Migration
  def change
    add_index :sites_cultivars, :site_id, unique: true
  end
end
