class AddSiteContainmentTable < ActiveRecord::Migration
  def up
    create_table :site_containment do |t|
      t.integer :containing_site_id, limit: 8, null: false
      t.integer :contained_site_id, limit: 8, null: false
    end

    execute %q{
        ALTER TABLE site_containment
            ADD CONSTRAINT "fk_containing_site_exists"
                FOREIGN KEY ("containing_site_id") REFERENCES "sites" ("id")
                    ON DELETE CASCADE ON UPDATE CASCADE,
            ADD CONSTRAINT "fk_contained_site_exists"
                FOREIGN KEY ("contained_site_id") REFERENCES "sites" ("id")
                    ON DELETE CASCADE ON UPDATE CASCADE;
    }
  end

  def down
    drop_table :site_containment
  end
end
