class AddSyncId < ActiveRecord::Migration
  class Machines < ActiveRecord::Base; end

  def self.up
    add_column :machines, :sync_host_id, :integer, :limit => 8
    add_column :machines, :sync_url, :string
    add_column :machines, :sync_contact, :string
    add_column :machines, :sync_start, :integer, :limit => 8
    add_column :machines, :sync_end, :integer, :limit => 8

    Machines.update_all("sync_host_id=0, sync_contact='David LeBauer', sync_url='https://ebi-forecast.igb.illinois.edu/pecan/dump/bety.tar.gz', sync_start=0, sync_end=0999999999", "hostname='ebi-forecast.igb.uiuc.edu'")
    Machines.update_all("sync_host_id=1, sync_contact='Mike Dietze', sync_url='http://psql-pecan.bu.edu/sync/dump/bety.tar.gz', sync_start=1000000001, sync_end=1999999999", "hostname='psql-pecan.bu.edu'")
#    Machines.update_all("sync_host_id=2, sync_contact='Shawn Serbin', sync_start=2000000001, sync_end=2999999999", "hostname='ebi-forecast.igb.illinois.edu'")
#    Machines.update_all("sync_host_id=3, sync_contact='Jeanne Osnas', sync_start=3000000001, sync_end=3999999999", "hostname='ebi-forecast.igb.illinois.edu'")
#    Machines.update_all("sync_host_id=4, sync_contact='Quinn Thomas', sync_start=4000000001, sync_end=4999999999", "hostname='ebi-forecast.igb.illinois.edu'")

    execute %{
      ALTER TABLE machines
        ADD CONSTRAINT unique_sync_host_id UNIQUE(sync_host_id);
    }
  end

  def self.down
    execute %{
      ALTER TABLE machines
        DROP CONSTRAINT unique_sync_host_id;
    }

    remove_column :machines, :sync_host_id
    remove_column :machines, :sync_url
    remove_column :machines, :sync_contact
    remove_column :machines, :sync_start
    remove_column :machines, :sync_end
  end
end
