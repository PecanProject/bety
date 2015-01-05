class AddCultivarsPfts < ActiveRecord::Migration
  def self.up
    create_table :cultivars_pfts, id: false do |t|
      t.integer :pft_id, :limit => 8, null: false
      t.integer :cultivar_id, :limit => 8, null: false

      t.timestamps
    end
    add_index :cultivars_pfts, [:pft_id, :cultivar_id], :unique => true, :name => :cultivar_pft_uniqueness

    execute %{

CREATE FUNCTION no_species_member(
  this_pft_id bigint
) RETURNS boolean AS $$
  DECLARE species_member_exists boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM pfts_species WHERE pft_id = this_pft_id) INTO species_member_exists;
  RETURN NOT species_member_exists;
END
$$ LANGUAGE plpgsql;

ALTER TABLE cultivars_pfts
  ADD CONSTRAINT pft_exists FOREIGN KEY (pft_id) REFERENCES pfts,
  ADD CONSTRAINT cultivar_exists FOREIGN KEY (cultivar_id) REFERENCES cultivars,
  ADD CONSTRAINT no_conflicting_member CHECK(no_species_member(pft_id));

CREATE FUNCTION no_cultivar_member(
  this_pft_id bigint
) RETURNS boolean AS $$
  DECLARE cultivar_member_exists boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM cultivars_pfts WHERE pft_id = this_pft_id) INTO cultivar_member_exists;
  RETURN NOT cultivar_member_exists;
END
$$ LANGUAGE plpgsql;


ALTER TABLE pfts_species
  ALTER COLUMN pft_id SET NOT NULL,
  ADD CONSTRAINT pft_exists FOREIGN KEY (pft_id) REFERENCES pfts NOT VALID,
  ALTER COLUMN specie_id SET NOT NULL,
  ADD CONSTRAINT species_exists FOREIGN KEY (specie_id) REFERENCES species NOT VALID,
  ADD CONSTRAINT no_conflicting_member CHECK(no_cultivar_member(pft_id));

}

  end

  def self.down

    execute %{

ALTER TABLE pfts_species
  DROP CONSTRAINT no_conflicting_member,
  DROP CONSTRAINT species_exists,
  ALTER COLUMN specie_id DROP NOT NULL,
  DROP CONSTRAINT pft_exists,
  ALTER COLUMN pft_id DROP NOT NULL;

DROP FUNCTION no_cultivar_member(bigint);

DROP TABLE cultivars_pfts;

DROP FUNCTION no_species_member(bigint);

}

  end
end
