class AddSitegroups < ActiveRecord::Migration

  def up
    this_hostid = Machine.new.hostid

    # The table we want to add:
    create_table :sitegroups do |t|
      t.string :name, null: false
      t.boolean :public_access, null: false, :default => false
      t.integer :user_id, :limit => 8, null: false
      t.timestamps
    end
    change_column :sitegroups, :id, :integer, :limit => 8
    # fix the counter for inserting new records
    execute %{
        SELECT setval('sitegroups_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
        ALTER TABLE sitegroups
            ALTER COLUMN created_at SET DEFAULT utc_now(),
            ALTER COLUMN updated_at SET DEFAULT utc_now(),
            ADD CONSTRAINT "fk_sitegroups_users"
                FOREIGN KEY ("user_id") REFERENCES "users" ("id")
                ON DELETE RESTRICT
                ON UPDATE CASCADE;
    }

    create_table :sitegroups_sites do |t|
      t.integer :sitegroup_id, :limit => 8, null: false
      t.integer :site_id, :limit => 8, null: false
      t.timestamps
    end
    change_column :sitegroups_sites, :id, :integer, :limit => 8
    # fix the counter for inserting new records and add foreign key constraints
    execute %{
        SELECT setval('sitegroups_sites_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
        ALTER TABLE sitegroups_sites
            ALTER COLUMN created_at SET DEFAULT utc_now(),
            ALTER COLUMN updated_at SET DEFAULT utc_now();

        ALTER TABLE "sitegroups_sites"
            ADD CONSTRAINT "fk_sitegroups_sites_sites"
                FOREIGN KEY ("site_id") REFERENCES "sites" ("id")
                ON DELETE CASCADE ON UPDATE CASCADE,
            ADD CONSTRAINT "fk_sitegroups_sites_sitegroups"
                FOREIGN KEY ("sitegroup_id") REFERENCES "sitegroups" ("id")
                ON DELETE CASCADE ON UPDATE CASCADE;
      }

    # only execute if migration is running on host 0
    if this_hostid == 0
      execute %{
        INSERT INTO sitegroups (name, public_access, user_id)
            VALUES('AmeriFlux', true, 55);
        INSERT INTO sitegroups_sites (sitegroup_id, site_id)
            SELECT (SELECT id FROM sitegroups WHERE name='AmeriFlux'), id
                FROM sites WHERE sitename LIKE '% (US-%)';
      }
    end
  end

  def down
    drop_table :sitegroups_sites
    drop_table :sitegroups
  end
end
