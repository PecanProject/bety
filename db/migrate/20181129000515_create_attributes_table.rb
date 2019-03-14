class CreateAttributesTable < ActiveRecord::Migration[5.1]
  def change
    this_hostid = Machine.new.hostid

    create_table :attributes, id: :bigint do |t|
      t.string :container_type, null: false
      t.integer :container_id, limit: 8, null: false
      t.jsonb :value, null: false, default: '{}'
      t.timestamps
    end

    add_index :attributes, :container_id
    add_index :attributes, :value, using: :gin

    reversible do |dir|
      dir.up do
        execute %{
          SELECT setval('attributes_id_seq', 1 + CAST(1e9 * #{this_hostid}::int AS bigint), FALSE);
          ALTER TABLE "attributes"
            ALTER COLUMN created_at SET DEFAULT utc_now(),
            ALTER COLUMN updated_at SET DEFAULT utc_now(),
            ADD CONSTRAINT container_type_id UNIQUE(container_type, container_id);
        }
      end
    end  
  end
end
