class AddExperimentsTable < ActiveRecord::Migration
  def up
    create_table :experiments do |t|
      t.string :name, null: false
      t.date :start_date
      t.date :end_date
      t.text :description, null: false, default: ''
      t.text :design, null: false, default: ''
      t.integer :user_id, :limit => 8, :null => false
      t.timestamps
    end

    create_table :experiments_sites do |t|
      t.integer :experiment_id, limit: 8, null: false
      t.integer :site_id, limit: 8, null: false
      t.timestamps
    end

    create_table :experiments_treatments do |t|
      t.integer :experiment_id, limit: 8, null: false
      t.integer :treatment_id, limit: 8, null: false
      t.timestamps
    end

    execute %q{
        ALTER TABLE experiments
            ALTER COLUMN created_at SET DEFAULT utc_now(),
            ALTER COLUMN updated_at SET DEFAULT utc_now(),
            ADD CONSTRAINT "properly_ordered_dates"
                CHECK (end_date >= start_date),
            ADD CONSTRAINT "fk_experiments_treatments"
                FOREIGN KEY ("user_id") REFERENCES "users" ("id");

        ALTER TABLE experiments_sites
            ALTER COLUMN created_at SET DEFAULT utc_now(),
            ALTER COLUMN updated_at SET DEFAULT utc_now(),
            ADD CONSTRAINT "fk_experiments_sites_experiments"
                FOREIGN KEY ("experiment_id") REFERENCES "experiments" ("id")
                ON DELETE CASCADE ON UPDATE CASCADE,
            ADD CONSTRAINT "fk_experiments_sites_sites"
                FOREIGN KEY ("site_id") REFERENCES "sites" ("id")
                ON DELETE CASCADE ON UPDATE CASCADE;

        ALTER TABLE experiments_treatments
            ALTER COLUMN created_at SET DEFAULT utc_now(),
            ALTER COLUMN updated_at SET DEFAULT utc_now(),
            ADD CONSTRAINT "fk_experiments_treatments_experiments"
                FOREIGN KEY ("experiment_id") REFERENCES "experiments" ("id")
                ON DELETE CASCADE ON UPDATE CASCADE,
            ADD CONSTRAINT "fk_experiments_treatments_treatments"
                FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id")
                ON DELETE CASCADE ON UPDATE CASCADE;

        CREATE TRIGGER update_experiments_timestamp
            BEFORE UPDATE ON experiments
            FOR EACH ROW
        EXECUTE PROCEDURE update_timestamp();

        CREATE TRIGGER update_experiments_sites_timestamp
            BEFORE UPDATE ON experiments_sites
            FOR EACH ROW
        EXECUTE PROCEDURE update_timestamp();

        CREATE TRIGGER update_experiments_treatments_timestamp
            BEFORE UPDATE ON experiments_treatments
            FOR EACH ROW
        EXECUTE PROCEDURE update_timestamp();

    }

  end

  def down
    drop_table :experiments_treatments
    drop_table :experiments_sites
    drop_table :experiments
  end
end
