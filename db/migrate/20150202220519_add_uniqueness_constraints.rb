class AddUniquenessConstraints < ActiveRecord::Migration
  def self.up

    # Use "%q" so that backspashes are taken literally (except when doubled).
    execute %q{

-- Some convenience functions
CREATE OR REPLACE FUNCTION normalize_whitespace(
  string text
) RETURNS text AS $$
DECLARE
  result text;
BEGIN
  SELECT TRIM(REGEXP_REPLACE(string, '\s+', ' ', 'g')) INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION normalize_whitespace(text) IS 'Removes leading and trailing whitespace from string '
  'and replaces internal sequences of whitespace with a single space character.';

CREATE OR REPLACE FUNCTION is_whitespace_normalized(
  string text
) RETURNS boolean AS $$
BEGIN
  RETURN string = normalize_whitespace(string);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION is_whitespace_normalized(text) IS 'Returns true if text contains no leading or trailing spaces, '
  'no whitespace other than spaces, and no consecutive spaces.';

CREATE OR REPLACE FUNCTION normalize_name_whitespace()
  RETURNS TRIGGER AS $$
BEGIN
  NEW.name = normalize_whitespace(NEW.name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- GH #182
ALTER TABLE cultivars ALTER COLUMN name SET NOT NULL;
ALTER TABLE cultivars ALTER COLUMN specie_id SET NOT NULL;
ALTER TABLE cultivars ADD CONSTRAINT unique_name_per_species UNIQUE (name, specie_id);

ALTER TABLE cultivars ADD CONSTRAINT normalized_names CHECK (is_whitespace_normalized(name));

DROP TRIGGER IF EXISTS normalize_cultivar_names ON cultivars;
CREATE TRIGGER normalize_cultivar_names
  BEFORE INSERT OR UPDATE ON cultivars
  FOR EACH ROW
    EXECUTE PROCEDURE normalize_name_whitespace();

-- GH #183
ALTER TABLE dbfiles ADD CONSTRAINT unique_filename_and_path_per_machine UNIQUE (file_name, file_path, machine_id);
ALTER TABLE dbfiles ALTER COLUMN file_name SET NOT NULL;
ALTER TABLE dbfiles ALTER COLUMN file_path SET NOT NULL;
ALTER TABLE dbfiles ALTER COLUMN machine_id SET NOT NULL;
ALTER TABLE dbfiles ADD CONSTRAINT no_space_in_file_name CHECK (file_name !~ '\s');
ALTER TABLE dbfiles ADD CONSTRAINT file_path_sanity_check CHECK (file_path ~ '^(([a-z.-]+:)?//?([.a-z0-9]+/)+[.A-Za-z0-9_-]*/?)?$');

-- GH #187
ALTER TABLE inputs_runs ALTER COLUMN input_id SET NOT NULL;
ALTER TABLE inputs_runs ALTER COLUMN run_id SET NOT NULL;
ALTER TABLE inputs_runs ADD CONSTRAINT unique_input_run_pair UNIQUE (input_id, run_id);

-- GH #188
ALTER TABLE inputs_variables ALTER COLUMN input_id SET NOT NULL;
ALTER TABLE inputs_variables ALTER COLUMN variable_id SET NOT NULL;
ALTER TABLE inputs_variables ADD CONSTRAINT unique_input_variable_pairs UNIQUE (input_id, variable_id);

-- GH #189
ALTER TABLE likelihoods ALTER COLUMN run_id SET NOT NULL;
ALTER TABLE likelihoods ALTER COLUMN variable_id SET NOT NULL;
ALTER TABLE likelihoods ALTER COLUMN input_id SET NOT NULL;
ALTER TABLE likelihoods ADD CONSTRAINT unique_run_variable_input_combination UNIQUE (run_id, variable_id, input_id);

-- GH #190
ALTER TABLE machines ALTER COLUMN hostname SET NOT NULL;
ALTER TABLE machines ADD CONSTRAINT unique_hostnames UNIQUE (hostname);

-- GH #192
ALTER TABLE managements_treatments ALTER COLUMN treatment_id SET NOT NULL;
ALTER TABLE managements_treatments ALTER COLUMN management_id SET NOT NULL;

-- GH #194
ALTER TABLE mimetypes ALTER COLUMN type_string SET NOT NULL;
ALTER TABLE mimetypes ADD CONSTRAINT unique_type_string UNIQUE (type_string);
ALTER TABLE mimetypes ADD CONSTRAINT valid_mime_type CHECK (type_string ~ '^(application|audio|chemical|drawing|image|i-world|message|model|multipart|music|paleovu|text|video|windows|www|x-conference|xgl|x-music|x-world)/[a-z.0-9_-]+( \((old|compiled elisp)\))?$');

-- GH #195
ALTER TABLE pfts_priors ALTER COLUMN pft_id SET NOT NULL;
ALTER TABLE pfts_priors ALTER COLUMN prior_id SET NOT NULL;

-- GH #197
ALTER TABLE pfts ADD CONSTRAINT unique_name_per_model UNIQUE (name, modeltype_id);
ALTER TABLE pfts ADD CONSTRAINT no_whitespace_in_name CHECK(name !~ '\s');

-- GH #198
ALTER TABLE posteriors ALTER COLUMN pft_id SET NOT NULL;
ALTER TABLE posteriors ALTER COLUMN format_id SET NOT NULL;
ALTER TABLE posteriors ADD CONSTRAINT unique_format_per_pft UNIQUE (pft_id, format_id);

-- GH #213
ALTER TABLE citations_sites ALTER COLUMN citation_id SET NOT NULL;
ALTER TABLE citations_sites ALTER COLUMN site_id SET NOT NULL;

-- GH #215
ALTER TABLE citations_treatments ALTER COLUMN citation_id SET NOT NULL;
ALTER TABLE citations_treatments ALTER COLUMN treatment_id SET NOT NULL;

    }

  end

  def self.down
    execute %q{

-- GH #182
ALTER TABLE cultivars ALTER COLUMN name DROP NOT NULL;
ALTER TABLE cultivars ALTER COLUMN specie_id DROP NOT NULL;
ALTER TABLE cultivars DROP CONSTRAINT unique_name_per_species;

ALTER TABLE cultivars DROP CONSTRAINT normalized_names;

DROP TRIGGER normalize_cultivar_names ON cultivars;

-- GH #183
ALTER TABLE dbfiles DROP CONSTRAINT unique_filename_and_path_per_machine;
ALTER TABLE dbfiles ALTER COLUMN file_name DROP NOT NULL;
ALTER TABLE dbfiles ALTER COLUMN file_path DROP NOT NULL;
ALTER TABLE dbfiles ALTER COLUMN machine_id DROP NOT NULL;
ALTER TABLE dbfiles DROP CONSTRAINT no_space_in_file_name;
ALTER TABLE dbfiles DROP CONSTRAINT file_path_sanity_check;

-- GH #187
ALTER TABLE inputs_runs ALTER COLUMN input_id DROP NOT NULL;
ALTER TABLE inputs_runs ALTER COLUMN run_id DROP NOT NULL;
ALTER TABLE inputs_runs DROP CONSTRAINT unique_input_run_pair;

-- GH #188
ALTER TABLE inputs_variables ALTER COLUMN input_id DROP NOT NULL;
ALTER TABLE inputs_variables ALTER COLUMN variable_id DROP NOT NULL;
ALTER TABLE inputs_variables DROP CONSTRAINT unique_input_variable_pairs;

-- GH #189
ALTER TABLE likelihoods ALTER COLUMN run_id DROP NOT NULL;
ALTER TABLE likelihoods ALTER COLUMN variable_id DROP NOT NULL;
ALTER TABLE likelihoods ALTER COLUMN input_id DROP NOT NULL;
ALTER TABLE likelihoods DROP CONSTRAINT unique_run_variable_input_combination;

-- GH #190
ALTER TABLE machines ALTER COLUMN hostname DROP NOT NULL;
ALTER TABLE machines DROP CONSTRAINT unique_hostnames;

-- GH #192
ALTER TABLE managements_treatments ALTER COLUMN treatment_id DROP NOT NULL;
ALTER TABLE managements_treatments ALTER COLUMN management_id DROP NOT NULL;

-- GH #194
ALTER TABLE mimetypes ALTER COLUMN type_string DROP NOT NULL;
ALTER TABLE mimetypes DROP CONSTRAINT unique_type_string;
ALTER TABLE mimetypes DROP CONSTRAINT valid_mime_type;

-- GH #195
ALTER TABLE pfts_priors ALTER COLUMN pft_id DROP NOT NULL;
ALTER TABLE pfts_priors ALTER COLUMN prior_id DROP NOT NULL;

-- GH #197
ALTER TABLE pfts DROP CONSTRAINT unique_name_per_model;
ALTER TABLE pfts DROP CONSTRAINT no_whitespace_in_name;

-- GH #198
ALTER TABLE posteriors ALTER COLUMN pft_id DROP NOT NULL;
ALTER TABLE posteriors ALTER COLUMN format_id DROP NOT NULL;
ALTER TABLE posteriors DROP CONSTRAINT unique_format_per_pft;

-- GH #213
ALTER TABLE citations_sites ALTER COLUMN citation_id DROP NOT NULL;
ALTER TABLE citations_sites ALTER COLUMN site_id DROP NOT NULL;

-- GH #215
ALTER TABLE citations_treatments ALTER COLUMN citation_id DROP NOT NULL;
ALTER TABLE citations_treatments ALTER COLUMN treatment_id DROP NOT NULL;



-- Drop functions:

DROP FUNCTION normalize_name_whitespace();

DROP FUNCTION is_whitespace_normalized(text);

DROP FUNCTION normalize_whitespace(text);

    }
  end
end
