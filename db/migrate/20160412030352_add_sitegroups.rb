class AddSitegroups < ActiveRecord::Migration

  def up
    # The table we want to add:
    create_table :sitegroups do |t|
      t.string :name, null: false
      t.boolean :public_access, :default => false
      t.integer :user_id, :limit => 8, null: false
      t.timestamps
    end
    change_column :sitegroups, :id, :integer, :limit => 8
    # fix the counter for  inserting new records
    execute %{
        select setval('sitegroups_id_seq', greatest(1, cast(1e9 * floor(nextval('users_id_seq') / 1e9) as bigint)), false);
    }

    create_table :sitegroups_sites do |t|
      t.integer :sitegroup_id, :limit => 8, null: false
      t.integer :site_id, :limit => 8, null: false
      t.timestamps
    end
    change_column :sitegroups_sites, :id, :integer, :limit => 8
    # fix the counter for  inserting new records
    execute %{
        select setval('sitegroups_sites_id_seq', greatest(1, cast(1e9 * floor(nextval('users_id_seq') / 1e9) as bigint)), false);        
    }

    # only execute if migration is running on host 0
    if Machine.new.hostid == 0
      execute %{
        insert into sitegroups (name, public_access, user_id, created_at, updated_at) values('AmeriFlux', true, 0, now(), now());
        insert into sitegroups_sites (sitegroup_id, site_id, created_at, updated_at) select (select id from sitegroups where name='AmeriFlux'), id, now(), now() from sites where sitename like '% (US-%)';
      }
    end
  end

  def down
    drop_table :sitegroups_sites
    drop_table :sitegroups
  end
end
