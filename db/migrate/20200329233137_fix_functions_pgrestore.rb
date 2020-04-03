class FixFunctionsPgrestore < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up do
        execute %{
CREATE OR REPLACE FUNCTION is_whitespace_normalized(
  string text
) RETURNS boolean AS $$
BEGIN
  RETURN string = public.normalize_whitespace(string);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION normalize_name_whitespace()
  RETURNS TRIGGER AS $$
BEGIN
  NEW.name = public.normalize_whitespace(NEW.name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_input_ids(
) RETURNS bigint[] AS $$
DECLARE
    id_array bigint[];
BEGIN
    SELECT
        ARRAY_AGG(id)
    FROM
        public.inputs
    INTO
        id_array;
    RETURN id_array;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_model_ids(
) RETURNS bigint[] AS $$
DECLARE
    id_array bigint[];
BEGIN
    SELECT
        ARRAY_AGG(id)
    FROM
        public.models
    INTO
        id_array;
    RETURN id_array;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_posterior_ids(
) RETURNS bigint[] AS $$
DECLARE
    id_array bigint[];
BEGIN
    SELECT
        ARRAY_AGG(id)
    FROM
        public.posteriors
    INTO
        id_array;
    RETURN id_array;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION no_cultivar_member(
  this_pft_id bigint
) RETURNS boolean AS $$
  DECLARE cultivar_member_exists boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM public.cultivars_pfts WHERE pft_id = this_pft_id) INTO cultivar_member_exists;
  RETURN NOT cultivar_member_exists;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION no_species_member(
  this_pft_id bigint
) RETURNS boolean AS $$
  DECLARE species_member_exists boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM public.pfts_species WHERE pft_id = this_pft_id) INTO species_member_exists;
  RETURN NOT species_member_exists;
END
$$ LANGUAGE plpgsql;
        }
      end
      dir.down do
        execute %{
CREATE OR REPLACE FUNCTION is_whitespace_normalized(
  string text
) RETURNS boolean AS $$
BEGIN
  RETURN string = normalize_whitespace(string);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION normalize_name_whitespace()
  RETURNS TRIGGER AS $$
BEGIN
  NEW.name = normalize_whitespace(NEW.name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_input_ids(
) RETURNS bigint[] AS $$
DECLARE
    id_array bigint[];
BEGIN
    SELECT
        ARRAY_AGG(id)
    FROM
        inputs
    INTO
        id_array;
    RETURN id_array;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_model_ids(
) RETURNS bigint[] AS $$
DECLARE
    id_array bigint[];
BEGIN
    SELECT
        ARRAY_AGG(id)
    FROM
        models
    INTO
        id_array;
    RETURN id_array;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_posterior_ids(
) RETURNS bigint[] AS $$
DECLARE
    id_array bigint[];
BEGIN
    SELECT
        ARRAY_AGG(id)
    FROM
        posteriors
    INTO
        id_array;
    RETURN id_array;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION no_cultivar_member(
  this_pft_id bigint
) RETURNS boolean AS $$
  DECLARE cultivar_member_exists boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM public.cultivars_pfts WHERE pft_id = this_pft_id) INTO cultivar_member_exists;
  RETURN NOT cultivar_member_exists;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION no_species_member(
  this_pft_id bigint
) RETURNS boolean AS $$
  DECLARE species_member_exists boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM pfts_species WHERE pft_id = this_pft_id) INTO species_member_exists;
  RETURN NOT species_member_exists;
END
$$ LANGUAGE plpgsql;
        }
      end
    end  
  end
end
