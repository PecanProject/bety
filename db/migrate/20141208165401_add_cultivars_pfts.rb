# Adds cultivars_pfts table, adds constraints and comments on it and on
# pfts_species, and adds uniqueness constraints to pfts table.
class AddCultivarsPfts < ActiveRecord::Migration

  def self.up
    # The table we want to add:
    create_table :cultivars_pfts, id: false do |t|
      t.integer :pft_id, :limit => 8, null: false
      t.integer :cultivar_id, :limit => 8, null: false

      t.timestamps
    end
    add_index :cultivars_pfts, [:pft_id, :cultivar_id], :unique => true, :name => :cultivar_pft_uniqueness


    # Now use SQL directly to add some constraints and comments to the new table
    # (and to the related pfts_species table):
    execute %{

COMMENT ON TABLE cultivars_pfts IS 'This table tells which cultivars are members of which pfts.  For each row, the cultivar with id "cultivar_id" is a member of the pft with id "pft_id".';


CREATE FUNCTION no_species_member(
  this_pft_id bigint
) RETURNS boolean AS $$
  DECLARE species_member_exists boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM pfts_species WHERE pft_id = this_pft_id) INTO species_member_exists;
  RETURN NOT species_member_exists;
END
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION no_species_member(bigint) IS 'Returns TRUE if the pft with id "this_pft_id" contains no members which are species (as opposed to cultivars).';


ALTER TABLE cultivars_pfts
  ADD CONSTRAINT pft_exists FOREIGN KEY (pft_id) REFERENCES pfts ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT cultivar_exists FOREIGN KEY (cultivar_id) REFERENCES cultivars ON UPDATE CASCADE,
  ADD CONSTRAINT no_conflicting_member CHECK(no_species_member(pft_id));

COMMENT ON CONSTRAINT pft_exists ON cultivars_pfts IS 'Ensure the referred-to pft exists, and clean up any references to it if it is deleted or updated.';
COMMENT ON CONSTRAINT cultivar_exists ON cultivars_pfts IS 'Ensure the referred-to cultivar exists, block its deletion if it is being used in a pft, and update the reference if the cultivar id number changes.';
COMMENT ON CONSTRAINT no_conflicting_member ON cultivars_pfts IS 'Ensure the pft_id does not refer to a pft having one or more species as members; pfts referred to by this table can only contain other cultivars.';



-- Now add similar comments and constraints to the (already-existing) pfts_species table:

COMMENT ON TABLE pfts_species IS 'This table tells which species are members of which pfts.  For each row, the species with id "specie_id" is a member of the pft with id "pft_id".';

CREATE FUNCTION no_cultivar_member(
  this_pft_id bigint
) RETURNS boolean AS $$
  DECLARE cultivar_member_exists boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM cultivars_pfts WHERE pft_id = this_pft_id) INTO cultivar_member_exists;
  RETURN NOT cultivar_member_exists;
END
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION no_cultivar_member(bigint)  IS 'Returns TRUE if the pft with id "this_pft_id" contains no members which are cultivars (as opposed to species).';


ALTER TABLE pfts_species
  ALTER COLUMN pft_id SET NOT NULL,
  ADD CONSTRAINT pft_exists FOREIGN KEY (pft_id) REFERENCES pfts ON DELETE CASCADE ON UPDATE CASCADE NOT VALID,
  ALTER COLUMN specie_id SET NOT NULL,
  ADD CONSTRAINT species_exists FOREIGN KEY (specie_id) REFERENCES species ON UPDATE CASCADE NOT VALID,
  ADD CONSTRAINT no_conflicting_member CHECK(no_cultivar_member(pft_id));

COMMENT ON CONSTRAINT pft_exists ON pfts_species IS 'Ensure the referred-to pft exists, and clean up any references to it if it is deleted or updated.';
COMMENT ON CONSTRAINT species_exists ON pfts_species IS 'Ensure the referred-to species exists, block its deletion if it is used in a pft, and update the reference if the species id number changes.';
COMMENT ON CONSTRAINT no_conflicting_member ON pfts_species IS 'Ensure the pft_id does not refer to a pft having one or more cultivars as members; pfts referred to by this table con only contain other species.';



-- Finally, declare (name, modeltype_id) to be a key for pfts:

ALTER TABLE pfts
  ALTER COLUMN name SET NOT NULL,
  ADD CONSTRAINT unique_names_per_modeltype UNIQUE(name, modeltype_id);

COMMENT ON COLUMN pfts.name IS 'pft names are unique within a given model type.';

}

  end









  def self.down

    execute %{

COMMENT ON COLUMN pfts.name IS 'unique identifier used by PEcAn.';

ALTER TABLE pfts
  ALTER COLUMN name DROP NOT NULL,
  DROP CONSTRAINT unique_names_per_modeltype;



ALTER TABLE pfts_species
  DROP CONSTRAINT no_conflicting_member,
  DROP CONSTRAINT species_exists,
  ALTER COLUMN specie_id DROP NOT NULL,
  DROP CONSTRAINT pft_exists,
  ALTER COLUMN pft_id DROP NOT NULL;

DROP FUNCTION no_cultivar_member(bigint);

COMMENT ON TABLE pfts_species IS NULL;



DROP TABLE cultivars_pfts;

DROP FUNCTION no_species_member(bigint);

}

  end
end
