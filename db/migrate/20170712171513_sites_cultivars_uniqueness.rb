class SitesCultivarsUniqueness < ActiveRecord::Migration
  def up
    this_hostid = Machine.new.hostid

    execute %{
      SELECT setval('sites_cultivars_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);

      ALTER TABLE sites_cultivars ADD CONSTRAINT unique_site_id UNIQUE (site_id);
    }
  end

  def down

    execute %{
      ALTER TABLE sites_cultivars DROP CONSTRAINT unique_site_id;
    }

  end
end
