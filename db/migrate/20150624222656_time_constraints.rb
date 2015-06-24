class TimeConstraints < ActiveRecord::Migration
  def self.up

    execute %q{

/* Returns the current UTC time as a timestamp (without time zone) */
CREATE OR REPLACE FUNCTION utc_now()
    RETURNS timestamp AS $$
BEGIN
    RETURN CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
END;
$$ LANGUAGE plpgsql;

/* On insertion, if created_at or updated_at isn't set explicitly, default to
the current UTC time: */
ALTER TABLE citations ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE citations_sites ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE citations_treatments ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE counties ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE covariates ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE cultivars ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE cultivars_pfts ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE current_posteriors ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE dbfiles ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE ensembles ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE entities ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE formats ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE formats_variables ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE inputs ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE inputs_runs ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE inputs_variables ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE likelihoods ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE location_yields ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE machines ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE managements ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE managements_treatments ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE methods ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE models ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE modeltypes ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE modeltypes_formats ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE pfts ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE pfts_priors ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE pfts_species ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE posterior_samples ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE posteriors ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE posteriors_ensembles ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE priors ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE projects ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE runs ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE sessions ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE sites ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE species ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE traits ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE treatments ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE users ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE variables ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE yields ALTER COLUMN created_at SET DEFAULT utc_now();
ALTER TABLE workflows ALTER COLUMN created_at SET DEFAULT utc_now();

ALTER TABLE citations ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE citations_sites ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE citations_treatments ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE counties ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE covariates ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE cultivars ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE cultivars_pfts ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE current_posteriors ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE dbfiles ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE ensembles ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE entities ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE formats ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE formats_variables ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE inputs ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE inputs_runs ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE inputs_variables ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE likelihoods ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE location_yields ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE machines ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE managements ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE managements_treatments ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE methods ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE models ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE modeltypes ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE modeltypes_formats ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE pfts ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE pfts_priors ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE pfts_species ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE posterior_samples ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE posteriors ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE posteriors_ensembles ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE priors ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE projects ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE runs ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE sessions ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE sites ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE species ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE traits ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE treatments ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE users ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE variables ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE yields ALTER COLUMN updated_at SET DEFAULT utc_now();
ALTER TABLE workflows ALTER COLUMN updated_at SET DEFAULT utc_now();

/* Also create trigger to set updated_at to the current UTC time whenever we do
an update that doesn't set updated_at explicitly: */
CREATE OR REPLACE FUNCTION update_timestamp() 
  RETURNS TRIGGER AS $$ 
BEGIN 
    IF
        NEW.updated_at = OLD.updated_at
    THEN
        NEW.updated_at = utc_now();
    END IF;
    RETURN NEW; 
END; 
$$ LANGUAGE plpgsql;


CREATE TRIGGER update_citations_timestamp
  BEFORE UPDATE ON citations
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_citations_sites_timestamp
  BEFORE UPDATE ON citations_sites
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_citations_treatments_timestamp
  BEFORE UPDATE ON citations_treatments
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_counties_timestamp
  BEFORE UPDATE ON counties
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_covariates_timestamp
  BEFORE UPDATE ON covariates
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_cultivars_timestamp
  BEFORE UPDATE ON cultivars
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_cultivars_pfts_timestamp
  BEFORE UPDATE ON cultivars_pfts
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_current_posteriors_timestamp
  BEFORE UPDATE ON current_posteriors
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_dbfiles_timestamp
  BEFORE UPDATE ON dbfiles
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_ensembles_timestamp
  BEFORE UPDATE ON ensembles
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_entities_timestamp
  BEFORE UPDATE ON entities
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_formats_timestamp
  BEFORE UPDATE ON formats
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_formats_variables_timestamp
  BEFORE UPDATE ON formats_variables
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_inputs_timestamp
  BEFORE UPDATE ON inputs
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_inputs_runs_timestamp
  BEFORE UPDATE ON inputs_runs
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_inputs_variables_timestamp
  BEFORE UPDATE ON inputs_variables
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_likelihoods_timestamp
  BEFORE UPDATE ON likelihoods
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_location_yields_timestamp
  BEFORE UPDATE ON location_yields
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_machines_timestamp
  BEFORE UPDATE ON machines
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_managements_timestamp
  BEFORE UPDATE ON managements
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_managements_treatments_timestamp
  BEFORE UPDATE ON managements_treatments
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_methods_timestamp
  BEFORE UPDATE ON methods
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_models_timestamp
  BEFORE UPDATE ON models
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_modeltypes_timestamp
  BEFORE UPDATE ON modeltypes
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_modeltypes_formats_timestamp
  BEFORE UPDATE ON modeltypes_formats
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_pfts_timestamp
  BEFORE UPDATE ON pfts
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_pfts_priors_timestamp
  BEFORE UPDATE ON pfts_priors
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_pfts_species_timestamp
  BEFORE UPDATE ON pfts_species
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_posterior_samples_timestamp
  BEFORE UPDATE ON posterior_samples
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_posteriors_timestamp
  BEFORE UPDATE ON posteriors
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_posteriors_ensembles_timestamp
  BEFORE UPDATE ON posteriors_ensembles
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_priors_timestamp
  BEFORE UPDATE ON priors
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_projects_timestamp
  BEFORE UPDATE ON projects
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_runs_timestamp
  BEFORE UPDATE ON runs
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_sessions_timestamp
  BEFORE UPDATE ON sessions
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_sites_timestamp
  BEFORE UPDATE ON sites
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_species_timestamp
  BEFORE UPDATE ON species
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_traits_timestamp
  BEFORE UPDATE ON traits
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_treatments_timestamp
  BEFORE UPDATE ON treatments
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_users_timestamp
  BEFORE UPDATE ON users
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_variables_timestamp
  BEFORE UPDATE ON variables
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_yields_timestamp
  BEFORE UPDATE ON yields
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();


CREATE TRIGGER update_workflows_timestamp
  BEFORE UPDATE ON workflows
  FOR EACH ROW
EXECUTE PROCEDURE update_timestamp();

}

  end

  def self.down

    execute %q{

ALTER TABLE citations ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE citations_sites ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE citations_treatments ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE counties ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE covariates ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE cultivars ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE cultivars_pfts ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE current_posteriors ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE dbfiles ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE ensembles ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE entities ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE formats ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE formats_variables ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE inputs ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE inputs_runs ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE inputs_variables ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE likelihoods ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE location_yields ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE machines ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE managements ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE managements_treatments ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE methods ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE models ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE modeltypes ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE modeltypes_formats ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE pfts ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE pfts_priors ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE pfts_species ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE posterior_samples ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE posteriors ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE posteriors_ensembles ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE priors ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE projects ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE runs ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE sessions ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE sites ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE species ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE traits ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE treatments ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE users ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE variables ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE yields ALTER COLUMN created_at DROP DEFAULT;
ALTER TABLE workflows ALTER COLUMN created_at DROP DEFAULT;

ALTER TABLE citations ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE citations_sites ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE citations_treatments ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE counties ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE covariates ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE cultivars ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE cultivars_pfts ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE current_posteriors ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE dbfiles ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE ensembles ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE entities ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE formats ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE formats_variables ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE inputs ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE inputs_runs ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE inputs_variables ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE likelihoods ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE location_yields ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE machines ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE managements ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE managements_treatments ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE methods ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE models ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE modeltypes ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE modeltypes_formats ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE pfts ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE pfts_priors ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE pfts_species ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE posterior_samples ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE posteriors ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE posteriors_ensembles ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE priors ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE projects ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE runs ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE sessions ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE sites ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE species ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE traits ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE treatments ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE users ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE variables ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE yields ALTER COLUMN updated_at DROP DEFAULT;
ALTER TABLE workflows ALTER COLUMN updated_at DROP DEFAULT;

DROP TRIGGER IF EXISTS update_citations_timestamp ON citations;
DROP TRIGGER IF EXISTS update_citations_sites_timestamp ON citations_sites;
DROP TRIGGER IF EXISTS update_citations_treatments_timestamp ON citations_treatments;
DROP TRIGGER IF EXISTS update_counties_timestamp ON counties;
DROP TRIGGER IF EXISTS update_covariates_timestamp ON covariates;
DROP TRIGGER IF EXISTS update_cultivars_timestamp ON cultivars;
DROP TRIGGER IF EXISTS update_cultivars_pfts_timestamp ON cultivars_pfts;
DROP TRIGGER IF EXISTS update_current_posteriors_timestamp ON current_posteriors;
DROP TRIGGER IF EXISTS update_dbfiles_timestamp ON dbfiles;
DROP TRIGGER IF EXISTS update_ensembles_timestamp ON ensembles;
DROP TRIGGER IF EXISTS update_entities_timestamp ON entities;
DROP TRIGGER IF EXISTS update_formats_timestamp ON formats;
DROP TRIGGER IF EXISTS update_formats_variables_timestamp ON formats_variables;
DROP TRIGGER IF EXISTS update_inputs_timestamp ON inputs;
DROP TRIGGER IF EXISTS update_inputs_runs_timestamp ON inputs_runs;
DROP TRIGGER IF EXISTS update_inputs_variables_timestamp ON inputs_variables;
DROP TRIGGER IF EXISTS update_likelihoods_timestamp ON likelihoods;
DROP TRIGGER IF EXISTS update_location_yields_timestamp ON location_yields;
DROP TRIGGER IF EXISTS update_machines_timestamp ON machines;
DROP TRIGGER IF EXISTS update_managements_timestamp ON managements;
DROP TRIGGER IF EXISTS update_managements_treatments_timestamp ON managements_treatments;
DROP TRIGGER IF EXISTS update_methods_timestamp ON methods;
DROP TRIGGER IF EXISTS update_models_timestamp ON models;
DROP TRIGGER IF EXISTS update_modeltypes_timestamp ON modeltypes;
DROP TRIGGER IF EXISTS update_modeltypes_formats_timestamp ON modeltypes_formats;
DROP TRIGGER IF EXISTS update_pfts_timestamp ON pfts;
DROP TRIGGER IF EXISTS update_pfts_priors_timestamp ON pfts_priors;
DROP TRIGGER IF EXISTS update_pfts_species_timestamp ON pfts_species;
DROP TRIGGER IF EXISTS update_posterior_samples_timestamp ON posterior_samples;
DROP TRIGGER IF EXISTS update_posteriors_timestamp ON posteriors;
DROP TRIGGER IF EXISTS update_posteriors_ensembles_timestamp ON posteriors_ensembles;
DROP TRIGGER IF EXISTS update_priors_timestamp ON priors;
DROP TRIGGER IF EXISTS update_projects_timestamp ON projects;
DROP TRIGGER IF EXISTS update_runs_timestamp ON runs;
DROP TRIGGER IF EXISTS update_sessions_timestamp ON sessions;
DROP TRIGGER IF EXISTS update_sites_timestamp ON sites;
DROP TRIGGER IF EXISTS update_species_timestamp ON species;
DROP TRIGGER IF EXISTS update_traits_timestamp ON traits;
DROP TRIGGER IF EXISTS update_treatments_timestamp ON treatments;
DROP TRIGGER IF EXISTS update_users_timestamp ON users;
DROP TRIGGER IF EXISTS update_variables_timestamp ON variables;
DROP TRIGGER IF EXISTS update_yields_timestamp ON yields;
DROP TRIGGER IF EXISTS update_workflows_timestamp ON workflows;

DROP FUNCTION utc_now();
DROP FUNCTION update_timestamp();

  }
  end
end
