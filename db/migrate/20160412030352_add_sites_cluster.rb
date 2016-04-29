class AddSitesCluster < ActiveRecord::Migration

  def up
    # The table we want to add:
    create_table :clusters do |t|
      t.string :name, null: false
      t.boolean :everybody, :default => false
      t.integer :user_id, :limit => 8, null: false
      t.timestamps
    end
    change_column :clusters, :id, :integer, :limit => 8
    # fix the counter for  inserting new records
    execute %{
        select setval('clusters_id_seq', greatest(1, cast(1e9 * floor(nextval('users_id_seq') / 1e9) as bigint)), false);
    }

    create_table :clusters_sites do |t|
      t.integer :cluster_id, :limit => 8, null: false
      t.integer :site_id, :limit => 8, null: false
      t.timestamps
    end
    change_column :clusters_sites, :id, :integer, :limit => 8
    # fix the counter for  inserting new records
    execute %{
        select setval('clusters_sites_id_seq', greatest(1, cast(1e9 * floor(nextval('users_id_seq') / 1e9) as bigint)), false);        
    }

    # only execute if migration is running on host 0
    if Machine.new.hostid == 0
      execute %{
        insert into clusters (name, everybody, user_id, created_at, updated_at) values('AmeriFlux', true, 0, now(), now());
        insert into clusters_sites (cluster_id, site_id, created_at, updated_at) select (select id from clusters where name='AmeriFlux'), id, now(), now() from sites where sitename like '% (US-%)';
      }
    end
  end

  def down
    drop_table :clusters_sites
    drop_table :clusters
  end
end
