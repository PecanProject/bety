class SetExperimentTableIdSeqVals < ActiveRecord::Migration
  def up
    this_hostid = Machine.new.hostid

    range_minimum = 10 ** 9 * this_hostid + 1
    range_maximum = 10 ** 9 * (this_hostid + 1) - 1

    execute %{
      SELECT setval('experiments_id_seq', GREATEST(#{range_minimum}, (SELECT max(id) + 1 FROM experiments WHERE id BETWEEN #{range_minimum} AND #{range_maximum}))::bigint, FALSE);
      SELECT setval('experiments_sites_id_seq', GREATEST(#{range_minimum}, (SELECT max(id) + 1 FROM experiments_sites WHERE id BETWEEN #{range_minimum} AND #{range_maximum}))::bigint, FALSE);
      SELECT setval('experiments_treatments_id_seq', GREATEST(#{range_minimum}, (SELECT max(id) + 1 FROM experiments_treatments WHERE id BETWEEN #{range_minimum} AND #{range_maximum}))::bigint, FALSE);
      ALTER TABLE experiments_sites ADD CONSTRAINT unique_experiment_site_pair UNIQUE (experiment_id, site_id);
      ALTER TABLE experiments_treatments ADD CONSTRAINT unique_experiment_treatment_pair UNIQUE (experiment_id, treatment_id);
    }
  end

  def down

    execute %{
      ALTER TABLE experiments_sites DROP CONSTRAINT unique_experiment_site_pair;
      ALTER TABLE experiments_treatments DROP CONSTRAINT unique_experiment_treatment_pair;
    }
    
  end
end
