class AddSitesCluster < ActiveRecord::Migration

  def up
    this_hostid = Machine.new.hostid

    # The table we want to add:
    create_table :clusters do |t|
      t.string :name, null: false
      t.boolean :everybody, null: false, :default => false
      t.integer :user_id, :limit => 8, null: false
      t.timestamps
    end
    change_column :clusters, :id, :integer, :limit => 8
    # fix the counter for  inserting new records
    execute %{
        SELECT setval('clusters_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
        ALTER TABLE clusters
            ALTER COLUMN created_at SET DEFAULT utc_now(),
            ALTER COLUMN updated_at SET DEFAULT utc_now(),
            ADD CONSTRAINT "fk_clusters_users"
                FOREIGN KEY ("user_id") REFERENCES "users" ("id")
                ON DELETE RESTRICT
                ON UPDATE CASCADE;
    }

    create_table :clusters_sites do |t|
      t.integer :cluster_id, :limit => 8, null: false
      t.integer :site_id, :limit => 8, null: false
      t.timestamps
    end
    change_column :clusters_sites, :id, :integer, :limit => 8
    # fix the counter for inserting new records and add foreign key constraints
    execute %{
        SELECT setval('clusters_sites_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
        ALTER TABLE clusters_sites
            ALTER COLUMN created_at SET DEFAULT utc_now(),
            ALTER COLUMN updated_at SET DEFAULT utc_now();

        ALTER TABLE "clusters_sites"
            ADD CONSTRAINT "fk_clusters_sites_sites"
                FOREIGN KEY ("site_id") REFERENCES "sites" ("id")
                ON DELETE CASCADE ON UPDATE CASCADE,
            ADD CONSTRAINT "fk_clusters_sites_clusters"
                FOREIGN KEY ("cluster_id") REFERENCES "clusters" ("id")
                ON DELETE CASCADE ON UPDATE CASCADE;
    }

    # only execute if migration is running on host 0
    if this_hostid == 0
      execute %{
        INSERT INTO clusters (name, everybody, user_id)
            VALUES('AmeriFlux', true, 0);
        INSERT INTO clusters_sites (cluster_id, site_id)
            SELECT (SELECT id FROM clusters WHERE name='AmeriFlux'), id
                FROM sites WHERE sitename LIKE '% (US-%)';
      }
    end
  end

  def down
    drop_table :clusters_sites
    drop_table :clusters
  end
end
