class AddIdToTable < ActiveRecord::Migration
  def up
    this_hostid = Machine.new.hostid

    execute %{
      ALTER TABLE "cultivars_pfts" ADD "id" bigserial;
      SELECT setval('cultivars_pfts_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
      ALTER TABLE "trait_covariate_associations" ADD "id" bigserial;
      SELECT setval('trait_covariate_associations_id_seq', GREATEST(1, CAST(1e9 * #{this_hostid}::int AS bigint)), FALSE);
    }
  end

  def down
    remove_column :cultivars_pfts, :id
    remove_column :trait_covariate_associations, :id
  end
end
