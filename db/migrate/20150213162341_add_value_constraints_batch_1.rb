class AddValueConstraintsBatch1 < ActiveRecord::Migration
  def self.up

    # Use "%q" so that backspashes are taken literally (except when doubled).
    execute %q{

/* Need to drop and later re-create views that depend on columns whose type we are changing. */
DROP VIEW IF EXISTS traits_and_yields_view;
DROP VIEW IF EXISTS traits_and_yields_view_private;
DROP VIEW IF EXISTS yieldsview_private;
DROP VIEW IF EXISTS traitsview_private;



/* THIS SECTION IS ONLY HERE TEMPORARILY! DELETE AFTER AddUniquenessConstraints MIGRATION IS ADDED! */
-- Some convenience functions
CREATE OR REPLACE FUNCTION normalize_whitespace(
  string text
) RETURNS text AS $$
DECLARE
  result text;
BEGIN
  /* non-breaking space (\u00A0) is not included in the \s class in some installations */
  SELECT TRIM(REGEXP_REPLACE(string, '[\u00a0\s]+', ' ', 'g')) INTO result;
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

/* END OF TEMPORARY SECTION */










/* This is based on http://www.w3.org/Addressing/URL/5_BNF.html */
CREATE OR REPLACE FUNCTION is_host_address(
  string text
) RETURNS boolean AS $body$
DECLARE
  xalphas text := $$([-\w$@.&+!*"'(),]|%[0-9a-f]{2})+$$;
  ialpha text := '[a-z]' || xalphas;
  hostname text := ialpha || '(\.' || ialpha || ')*';
  hostnumber text := '\d+\.\d+\.\d+\.\d+';
  host text := '(' || hostname || '|' || hostnumber || ')';
BEGIN
  RETURN (string ~ ('^' || host || '$'));
END;
$body$ LANGUAGE plpgsql;


/* This is loosely based on http://www.w3.org/Addressing/URL/5_BNF.html and should suffice for our purposes. */
CREATE OR REPLACE FUNCTION is_url_or_empty(
  string text
) RETURNS boolean AS $body$
DECLARE
  xalphas text := $$([-\w$@.&+!*"'(),]|%[0-9a-f]{2})+$$;
  ialpha text := '[a-z]' || xalphas;
  hostname text := ialpha || '(\.' || ialpha || ')*';
  hostnumber text := '\d+\.\d+\.\d+\.\d+';

  scheme text := '(https?|ftp)';
  host text := '(' || hostname || '|' || hostnumber || ')';
  optional_port text := '(:\d+)?';
  path text := '(/' || xalphas || ')*';
  optional_query_string text := '(\?' || xalphas || ')?';

  url text := scheme || '://' || host || optional_port || path || optional_query_string;
BEGIN
  RETURN (string ~ url OR string = '');
END;
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_wellformed_email(
  string text
) RETURNS boolean AS $body$
DECLARE 
  xalphas text := $$([-\w$@.&+!*"'(),]|%[0-9a-f]{2})+$$;
  ialpha text := '[a-z]' || xalphas;
  hostname text := ialpha || '(\.' || ialpha || ')*';

  email text := FORMAT('%s@%s', xalphas, hostname);
BEGIN
  RETURN (string ~ email);
END;
$body$ LANGUAGE plpgsql;
 



/* New Domains */

-- This is used by covariates, traits, and yields:
CREATE DOMAIN statnames AS TEXT CHECK (VALUE IN ('SD', 'SE', 'MSE', '95%CI', 'LSD', 'MSD', 'HSD', '')) DEFAULT '' NOT NULL;

-- This is used by inputs, traits, users, and yields:
CREATE DOMAIN level_of_access AS INTEGER CHECK (VALUE BETWEEN 1 AND 4) NOT NULL;



/* CITATIONS */

ALTER TABLE citations ALTER COLUMN author SET NOT NULL,
                      ADD CHECK (is_whitespace_normalized(author));

ALTER TABLE citations ALTER COLUMN year SET NOT NULL,
                      ADD CHECK (year <= EXTRACT(year FROM NOW()) + 1);
/* ALTER TABLE citations ADD CHECK (year > 1800); ??? */

/* FIX */ UPDATE citations SET title = normalize_whitespace(title) WHERE NOT is_whitespace_normalized(title);
ALTER TABLE citations ALTER COLUMN title SET NOT NULL,
                      ADD CHECK (is_whitespace_normalized(title));

ALTER TABLE citations ALTER COLUMN journal SET NOT NULL,
                      ALTER COLUMN journal SET DEFAULT '',
                      ADD CHECK (is_whitespace_normalized(journal));

-- decide if vol = 0 is allowed before adding this:
/* ALTER TABLE citations ADD CHECK (vol > 0); */

ALTER TABLE citations ALTER COLUMN pg SET NOT NULL,
                      ALTER COLUMN pg SET DEFAULT '';

-- Check that pg is either empty or is positive integer possibly followed by and
-- n-dash and another positive integer:
ALTER TABLE citations ADD CHECK (pg ~ '^([1-9]\d*(\u2013[1-9]\d*)?)?$');

ALTER TABLE citations ALTER COLUMN url SET NOT NULL,
                      ALTER COLUMN url SET DEFAULT '',
                      ADD CHECK (is_url_or_empty(url) OR url ~ '^\(.+\)$');

ALTER TABLE citations ALTER COLUMN pdf SET NOT NULL,
                      ALTER COLUMN pdf SET DEFAULT '',
                      ADD CHECK (is_url_or_empty(pdf) OR pdf ~ '^\(.+\)$');

ALTER TABLE citations ADD CHECK (doi ~ '^(|10\.\d+(\.\d+)?/.+)$');




/* COVARIATES */

-- See GH #216:
/* ALTER TABLE covariates ALTER COLUMN trait_id SET NOT NULL; */
/* ALTER TABLE covariates ALTER COLUMN variable_id SET NOT NULL; */

-- pending cleanup:
/* ALTER TABLE covariates ALTER COLUMN level SET NOT NULL; */

-- decide whether to use >= 1 or >= 2
/* ALTER TABLE covariates ADD CHECK (n >= 2); */

ALTER TABLE covariates ALTER COLUMN statname SET DATA TYPE statnames;
-- see stat-statname consistency violations:
-- SELECT * FROM  covariates WHERE NOT (statname = '' AND stat IS NULL OR statname != '' AND stat IS NOT NULL);
-- possible consistency constraint:
/* ALTER TABLE covariates ADD CHECK (statname = '' AND stat IS NULL OR statname != '' AND stat IS NOT NULL); */
-- other consistency constraints to be decided


/* CULTIVARS */

ALTER TABLE cultivars ALTER COLUMN ecotype SET NOT NULL,
                      ALTER COLUMN ecotype SET DEFAULT '';
ALTER TABLE cultivars ALTER COLUMN notes SET NOT NULL,
                      ALTER COLUMN notes SET DEFAULT '';


/* DBFILES */

ALTER TABLE dbfiles ADD CHECK (md5 ~ '^([\da-z]{32})?$');
ALTER TABLE dbfiles ADD CHECK (container_type IN ('Model','Posterior','Input'));
-- consistency checks between this table and inputs, models, and posteriors tables are part of a separate migration


/* ENSEMBLES */

ALTER TABLE ensembles ALTER COLUMN notes SET NOT NULL,
                      ALTER COLUMN notes SET DEFAULT '';
ALTER TABLE ensembles ALTER COLUMN runtype SET NOT NULL,
                      CHECK (runtype IN ('ensemble', 'sensitivity analysis'));

/* ENTITIES */

ALTER TABLE entities ALTER COLUMN name SET NOT NULL,
                     ALTER COLUMN name SET DEFAULT '';
ALTER TABLE entities ADD CHECK (is_whitespace_normalized(name));
ALTER TABLE entities ALTER COLUMN notes SET NOT NULL,
                     ALTER COLUMN notes SET DEFAULT '';


/* FORMATS */

ALTER TABLE formats ALTER COLUMN dataformat SET NOT NULL,
                    ALTER COLUMN dataformat SET DEFAULT '';
ALTER TABLE formats ALTER COLUMN notes SET NOT NULL,
                    ALTER COLUMN notes SET DEFAULT '';
ALTER TABLE formats ALTER COLUMN name SET NOT NULL,
                    ADD CHECK (is_whitespace_normalized(name));
ALTER TABLE formats ALTER COLUMN header SET NOT NULL,
                    ALTER COLUMN header SET DEFAULT '';
ALTER TABLE formats ALTER COLUMN skip SET NOT NULL,
                    ALTER COLUMN skip SET DEFAULT '';


/* FORMATS_VARIABLES */

ALTER TABLE formats_variables ALTER COLUMN format_id SET NOT NULL;
ALTER TABLE formats_variables ALTER COLUMN variable_id SET NOT NULL;
ALTER TABLE formats_variables ALTER COLUMN name SET NOT NULL,
                              ALTER COLUMN name SET DEFAULT '';
ALTER TABLE formats_variables ALTER COLUMN unit SET NOT NULL,
                              ALTER COLUMN unit SET DEFAULT '';
ALTER TABLE formats_variables ALTER COLUMN storage_type SET NOT NULL,
                              ALTER COLUMN storage_type SET DEFAULT '';

-- decide on constraints

/* INPUTS */

ALTER TABLE inputs ALTER COLUMN notes SET NOT NULL,
                   ALTER COLUMN SET DEFAULT '';

-- see violators of potential not null constraints:
-- SELECT start_date, end_date FROM inputs WHERE start_date IS NULL OR end_date IS NULL;
/* ALTER TABLE inputs ALTER COLUMN start_date SET NOT NULL; */
/* ALTER TABLE inputs ALTER COLUMN end_date SET NOT NULL; */
-- see violators of CHECK (start_date < end_date):
-- SELECT start_date, end_date FROM inputs WHERE start_date >= end_date;
/* ALTER TABLE inputs ADD CHECK (start_date < end_date); */
-- see future dates:
-- SELECT start_date, end_date FROM inputs WHERE start_date > NOW() OR end_date > NOW();
/* ALTER TABLE inputs CHECK (end_date < NOW()); */

ALTER TABLE inputs ALTER COLUMN name SET NOT NULL,
                   ADD CHECK (is_whitespace_normalized(name));
ALTER TABLE inputs ALTER COLUMN access_level SET DATA TYPE level_of_access;
ALTER TABLE inputs ALTER COLUMN raw SET NOT NULL;
-- add after cleanup:
/* ALTER TABLE inputs ALTER COLUMN format_id SET NOT NULL; */

/* LIKELIHOODS */

-- no current constraints other than those in AddUniquenessConstraints migration


/* MACHINES */

ALTER TABLE machines ADD CHECK (is_host_address(hostname));
-- decide on additional constraints (if any)

/* MANAGEMENTS */

-- possibly:
-- ALTER TABLE managements ALTER COLUMN citation_id SET NOT NULL;

-- show null dateloc counts:
--   SELECT COUNT(*), date FROM managements WHERE dateloc IS NULL GROUP BY date;
/* ALTER TABLE managements ALTER COLUMN dateloc SET NOT NULL; */
-- decide on other date, dateloc constraints

ALTER TABLE managements ALTER COLUMN mgmttype SET NOT NULL;
-- get a count of unrecognized mgmttype values:
-- SELECT COUNT(*) FROM managements WHERE mgmttype NOT IN ( 'burned', 'coppice', 'cultivated', 'cultivated or grazed', 'fertilization_Ca', 'fertilization_K', 'fertilization_N', 'fertilization_P', 'fertilization_other', 'fungicide', 'grazed', 'harvest', 'herbicide', 'irrigation', 'light', 'pesticide', 'planting (plants / m2)', 'row spacing', 'seeding', 'tillage','warming_soil','warming_air','initiation of natural succession','major storm','root exclusion', 'trenching', 'CO2 fumigation', 'soil disturbance', 'rain exclusion');
-- show what these values are:
-- SELECT DISTINCT mgmttype FROM managements WHERE mgmttype NOT IN ( 'burned', 'coppice', 'cultivated', 'cultivated or grazed', 'fertilization_Ca', 'fertilization_K', 'fertilization_N', 'fertilization_P', 'fertilization_other', 'fungicide', 'grazed', 'harvest', 'herbicide', 'irrigation', 'light', 'pesticide', 'planting (plants / m2)', 'row spacing', 'seeding', 'tillage','warming_soil','warming_air','initiation of natural succession','major storm','root exclusion', 'trenching', 'CO2 fumigation', 'soil disturbance', 'rain exclusion');

-- decide on level and units constraints

ALTER TABLE managements ALTER COLUMN notes SET NOT NULL,
                        ALTER COLUMN notes SET DEFAULT '';


/* METHODS */

ALTER TABLE methods ALTER COLUMN name SET NOT NULL;
ALTER TABLE methods ADD CHECK (is_whitespace_normalized(name));
ALTER TABLE methods ALTER COLUMN description SET NOT NULL;
-- Additional constraints will be added when candidate key is implemented.


/* MIMETYPES */

-- to decide:
/* ALTER TABLE mimetypes ADD CHECK(type_string ~ '^(application|audio|chemical|drawing|image|i-world|message|model|multipart|music|paleovu|text|video|windows|www|x-conference|xgl|x-music|x-world)/[a-z.0-9_-]+( \((old|compiled elisp)\))?$'); */


/* MODELS */

ALTER TABLE models ALTER COLUMN model_name SET NOT NULL,
                   ADD CHECK (model_name !~ '\s');
ALTER TABLE models ALTER COLUMN revision SET NOT NULL,
                   ADD CHECK (revision !~ '\s');


/* MODELTYPES */

ALTER TABLE modeltypes ALTER COLUMN name SET NOT NULL;
ALTER TABLE modeltypes ADD CHECK (name !~ '\s');


/* MODELTYPES_FORMATS */

ALTER TABLE modeltypes_formats ALTER COLUMN tag SET NOT NULL;
-- use one of these constraints:
/* ALTER TABLE modeltypes_formats ADD CHECK (tag !~ '\w'); */
/* ALTER TABLE modeltypes_formats ADD CHECK (tag ~ '^[a-z]+$'); */
ALTER TABLE modeltypes_formats ALTER COLUMN required SET NOT NULL;
ALTER TABLE modeltypes_formats ALTER COLUMN input SET NOT NULL;


/* PFTS */

ALTER TABLE pfts ALTER COLUMN definition SET NOT NULL;
ALTER TABLE pfts ADD CHECK (name ~ '^[-\w]+(\.[-\w]+)*$');
ALTER TABLE pfts ALTER COLUMN pft_type SET NOT NULL;
ALTER TABLE pfts ADD CHECK (pft_type IN ('plant', 'cultivar', ''));

/* PRIORS */

ALTER TABLE priors ALTER COLUMN phylogeny SET NOT NULL;
ALTER TABLE priors ADD CHECK (is_whitespace_normalized(phylogeny));
ALTER TABLE priors ALTER COLUMN distn SET NOT NULL;
ALTER TABLE priors ADD CHECK (distn IN ('beta', 'binom', 'cauchy', 'chisq', 'exp', 'f', 'gamma', 'geom', 'hyper', 'lnorm', 'logis', 'nbinom', 'norm', 'pois', 't', 'unif', 'weibull', 'wilcox'));
ALTER TABLE priors ALTER COLUMN parama SET NOT NULL;
ALTER TABLE priors ADD CHECK (n >= 0);

/* PROJECTS */

ALTER TABLE projects ALTER COLUMN name SET NOT NULL;
ALTER TABLE projects ALTER COLUMN outdir SET NOT NULL;
-- decide on other constraints for outdir
ALTER TABLE projects ALTER COLUMN description SET NOT NULL;


/* RUNS */

ALTER TABLE runs ALTER COLUMN outdir SET NOT NULL;
ALTER TABLE runs ALTER COLUMN outprefix SET NOT NULL;
ALTER TABLE runs ALTER COLUMN setting SET NOT NULL;
ALTER TABLE runs ALTER COLUMN started_at SET NOT NULL;
ALTER TABLE runs ADD CHECK (started_at <= NOW());
-- we are probably removing these columns:
-- ALTER TABLE runs ALTER COLUMN start_date SET NOT NULL;
-- ALTER TABLE runs ALTER COLUMN end_date SET NOT NULL;


/* SITES */

ALTER TABLE sites ALTER COLUMN city SET NOT NULL;
ALTER TABLE sites ALTER COLUMN state SET NOT NULL;
ALTER TABLE sites ALTER COLUMN country SET NOT NULL;
ALTER TABLE sites ADD CHECK (mat BETWEEN -25 AND 40);
ALTER TABLE sites ADD CHECK (map BETWEEN 0 AND 12000);
ALTER TABLE sites ALTER COLUMN soil SET NOT NULL;
-- see bad soil values:
--   SELECT id, soil FROM sites WHERE NOT soil IN ('clay', 'sandy clay', 'sandy clay loam', 'sandy loam', 'loamy sand', 'sand', 'clay loam', 'loam', 'silty clay', 'silty clay loam', 'silt loam', 'silt', '') ORDER BY id;
/* ALTER TABLE sites ADD CHECK (soil IN ('clay', 'sandy clay', 'sandy clay loam', 'sandy loam', 'loamy sand', 'sand', 'clay loam', 'loam', 'silty clay', 'silty clay loam', 'silt loam', 'silt', '')); */
ALTER TABLE sites ADD CHECK (som BETWEEN 0 AND 100);
ALTER TABLE sites ALTER COLUMN notes SET NOT NULL;
ALTER TABLE sites ALTER COLUMN soilnotes SET NOT NULL;
ALTER TABLE sites ALTER COLUMN sitename SET NOT NULL;
ALTER TABLE sites ADD CHECK (is_whitespace_normalized(sitename));
ALTER TABLE sites ADD CHECK (sand_pct >= 0 AND clay_pct >= 0 AND sand_pct <= 100 AND clay_pct <= 100 AND sand_pct + clay_pct <= 100);
ALTER TABLE sites ADD CHECK ( (ST_X(ST_CENTROID(geometry)) BETWEEN -180 AND 180) AND (ST_Y(ST_CENTROID(geometry)) BETWEEN -90 AND 90) AND (ST_Z(ST_CENTROID(geometry)) BETWEEN -100 AND 10000) );


/* SPECIES */

ALTER TABLE species ADD CHECK (spcd BETWEEN 0 AND 10000);
ALTER TABLE species ALTER COLUMN genus SET NOT NULL;
ALTER TABLE species ADD CHECK (genus ~ '^([A-Z][-a-z]*)?$');
ALTER TABLE species ALTER COLUMN species SET NOT NULL;
-- see bad species names:
--   SELECT genus, scientificname, species FROM species WHERE species !~ '^([a-z-]*| var. | ssp. | \u00d7 | L.($| ))*$';
/* ALTER TABLE species ADD CHECK (species ~ '^([a-z-]*| var. | ssp. | \u00d7 | L.($| ))*$'); */
ALTER TABLE species ALTER COLUMN scientificname SET NOT NULL;
ALTER TABLE species ADD CHECK (is_whitespace_normalized(scientificname));
ALTER TABLE species ALTER COLUMN commonname SET NOT NULL;
ALTER TABLE species ADD CHECK (is_whitespace_normalized(commonname));
ALTER TABLE species ALTER COLUMN notes SET NOT NULL;
-- see rows that violate proposed consistency constraint:
-- SELECT scientificname, genus, species FROM species WHERE scientificname !~ FORMAT('^%s %s', genus, species) AND species != '';

-- normalize cross in hybrids:
CREATE OR REPLACE FUNCTION replace_x() 
  RETURNS TRIGGER AS $$ 
BEGIN
    NEW.species = REPLACE(NEW.species, ' x ', E' \u00d7 ');
    NEW.scientificname = REPLACE(NEW.scientificname, ' x ', E' \u00d7 ');
    RETURN NEW; 
END; 
$$ LANGUAGE plpgsql;

CREATE TRIGGER normalize_cross
  BEFORE INSERT OR UPDATE OF species, scientificname ON species
  FOR EACH ROW
  WHEN (NEW.species ~ ' x ' OR NEW.scientificname ~ ' x ') 
EXECUTE PROCEDURE replace_x(); 




/* TRAIT_COVARIATE_ASSOCIATIONS */

ALTER TABLE trait_covariate_associations ALTER COLUMN required SET NOT NULL;


/* TRAITS */

ALTER TABLE traits ALTER COLUMN statname SET NOT NULL;
ALTER TABLE traits ALTER COLUMN statname SET DATA TYPE statnames;

-- see species-cultivar inconsistencies:
--   SELECT t_sp.scientificname AS "species referred to by traits table", c_sp.scientificname AS "species matching cultivar", c.name FROM traits t JOIN cultivars c ON t.cultivar_id = c.id JOIN species t_sp ON t_sp.id = t.specie_id JOIN species c_sp ON c.specie_id = c_sp.id WHERE t.specie_id != c.specie_id;
-- decide on consistency constraint
ALTER TABLE traits ALTER COLUMN notes SET NOT NULL;
/* ALTER TABLE traits ALTER COLUMN checked SET NOT NULL; */
ALTER TABLE traits ADD CHECK (checked BETWEEN -1 AND 1);
-- add after cleaning up rows where access_level = 0; may need to drop and re-add dependent views before doing this:
/* ALTER TABLE traits ALTER COLUMN access_level SET DATA TYPE level_of_access; */

-- see count of NULLs in proposed key columns:
--   SELECT COUNT(*) AS "total number of rows", SUM((site_id IS NULL)::int) AS "site_id NULLs", SUM((specie_id IS NULL)::int) AS "species_id NULLs", SUM((citation_id IS NULL)::int) AS "citation_id NULLs", SUM((cultivar_id IS NULL)::int) AS "cultivar_id NULLs", SUM((treatment_id IS NULL)::int) AS "treatment_id NULLs", SUM((date IS NULL)::int) AS "date NULLs", SUM((time IS NULL)::int) AS "time NULLs", SUM((variable_id IS NULL)::int) AS "variable_id NULLs", SUM((entity_id IS NULL)::int) AS "entity_id NULLs", SUM((method_id IS NULL)::int) AS "method_id NULLs", SUM((date_year IS NULL)::int) AS "date_year NULLs", SUM((date_month IS NULL)::int) AS "date_month NULLs", SUM((date_day IS NULL)::int) AS "date_day NULLs", SUM((time_hour IS NULL)::int) AS "time_hour NULLs", SUM((time_minute)::int) AS "time_minute" FROM traits;
-- more info about missing date and time info:
--   SELECT COUNT(*) AS "total number of rows", SUM((date IS NULL AND date_year IS NULL AND date_month IS NULL AND date_day IS NULL)::int) AS "rows with no date info", SUM((time IS NULL AND time_hour IS NULL AND time_minute IS NULL)::int) AS "rows with no time into" FROM traits;


/* TREATMENTS */

ALTER TABLE treatments ALTER COLUMN name SET NOT NULL;
/* FIX */ UPDATE treatments SET name = normalize_whitespace(name) WHERE NOT is_whitespace_normalized(name);
ALTER TABLE treatments ADD CHECK (is_whitespace_normalized(name));
ALTER TABLE treatments ALTER COLUMN definition SET NOT NULL;
ALTER TABLE treatments ADD CHECK (is_whitespace_normalized(definition));


/* USERS */

ALTER TABLE users ALTER COLUMN login SET NOT NULL;
ALTER TABLE users ADD CHECK (login ~ '^[a-z\d_][a-z\d_.@-]{2,39}$'); -- matches Rails app requirements
ALTER TABLE users ALTER COLUMN name SET NOT NULL;
ALTER TABLE users ADD CHECK (is_whitespace_normalized(name));
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
ALTER TABLE users ADD CHECK (is_wellformed_email(email));
ALTER TABLE users ALTER COLUMN city SET NOT NULL;
/* FIX */ UPDATE users SET city = normalize_whitespace(city) WHERE NOT is_whitespace_normalized(city);
ALTER TABLE users ADD CHECK (is_whitespace_normalized(city));
ALTER TABLE users ALTER COLUMN country SET NOT NULL;
ALTER TABLE users ADD CHECK (is_whitespace_normalized(country));
ALTER TABLE users ALTER COLUMN crypted_password SET NOT NULL;
ALTER TABLE users ADD CHECK (crypted_password ~ '^[0-9a-f]{40}$');
/* ALTER TABLE users ALTER COLUMN salt SET NOT NULL; */
ALTER TABLE users ADD CHECK (salt ~ '^[0-9a-f]{40}$');
ALTER TABLE users ALTER COLUMN access_level SET DATA TYPE level_of_access;
ALTER TABLE users ALTER COLUMN page_access_level SET DATA TYPE level_of_access;
/* FIX */ UPDATE users SET apikey = '' WHERE apikey IS NULL;
ALTER TABLE users ALTER COLUMN apikey SET NOT NULL;
ALTER TABLE users ADD CHECK (apikey ~ '^[0-9a-zA-Z+/]{40}$' OR apikey = '');
ALTER TABLE users ALTER COLUMN state_prov SET NOT NULL;
ALTER TABLE users ADD CHECK (is_whitespace_normalized(state_prov));
ALTER TABLE users ALTER COLUMN postal_code SET NOT NULL;
ALTER TABLE users ADD CHECK (is_whitespace_normalized(postal_code));


/* VARIABLES */

ALTER TABLE variables ALTER COLUMN description SET NOT NULL;
-- can't do this until trigger function is fixed:
/* ALTER TABLE variables ADD CHECK (is_whitespace_normalized(description)); */
ALTER TABLE variables ALTER COLUMN units SET NOT NULL;
ALTER TABLE variables ADD CHECK (is_whitespace_normalized(units));


/* WORKFLOWS */

ALTER TABLE workflows ALTER COLUMN folder SET NOT NULL;
ALTER TABLE workflows ADD CHECK (is_whitespace_normalized(folder));
ALTER TABLE workflows ALTER COLUMN hostname SET NOT NULL;
ALTER TABLE workflows ADD CHECK (is_whitespace_normalized(hostname));
ALTER TABLE workflows ALTER COLUMN params SET NOT NULL;
ALTER TABLE workflows ADD CHECK (is_whitespace_normalized(params));
ALTER TABLE workflows ALTER COLUMN advanced_edit SET NOT NULL;


/* YIELDS */

ALTER TABLE yields ALTER COLUMN mean SET NOT NULL;
/* FIX */ UPDATE yields SET statname = '' WHERE statname IS NULL;
ALTER TABLE yields ALTER COLUMN statname SET NOT NULL;
ALTER TABLE yields ALTER COLUMN statname SET DATA TYPE statnames;
/* FIX */ UPDATE yields SET notes = '' WHERE notes IS NULL;
ALTER TABLE yields ALTER COLUMN notes SET NOT NULL;
/* ALTER TABLE yields ALTER COLUMN checked SET NOT NULL; */
ALTER TABLE yields ADD CHECK (checked BETWEEN -1 AND 1);
ALTER TABLE yields ALTER COLUMN access_level SET DATA TYPE level_of_access;
-- see species-cultivar inconsistencies:
--   SELECT y_sp.scientificname AS "species referred to by yields table", c_sp.scientificname AS "species matching cultivar", c.name FROM yields y JOIN cultivars c ON y.cultivar_id = c.id JOIN species y_sp ON y_sp.id = y.specie_id JOIN species c_sp ON c.specie_id = c_sp.id WHERE y.specie_id != c.specie_id;





CREATE VIEW traitsview_private AS
        SELECT
                CAST('traits' AS VARCHAR(10)) AS result_type,
                traits.id AS id,
                traits.citation_id,
                traits.site_id,
                traits.treatment_id,
                sites.sitename,
                sites.city,
                ST_Y(ST_CENTROID(sites.geometry)) AS lat,
                ST_X(ST_CENTROID(sites.geometry)) AS lon,
                species.scientificname,
                species.commonname,
                species.genus,
                species.id AS species_id,
                traits.cultivar_id, 
                citations.author AS author,
                citations.year AS citation_year,
                treatments.name AS treatment,
                traits.date,
                extract(month from traits.date) AS month,
                extract(year from traits.date) AS year,
                traits.dateloc,
                variables.name AS trait,
                variables.description AS trait_description,
                traits.mean,
                variables.units,
                traits.n,
                traits.statname,
                traits.stat,
                traits.notes,
                traits.access_level, 
                traits.checked, 
                users.login, 
                users.name, 
                users.email
        FROM
                          traits
                LEFT JOIN sites ON traits.site_id = sites.id
                LEFT JOIN species ON traits.specie_id = species.id
                LEFT JOIN citations ON traits.citation_id = citations.id
                LEFT JOIN treatments ON traits.treatment_id = treatments.id
                LEFT JOIN variables ON traits.variable_id = variables.id
                LEFT JOIN users ON traits.user_id = users.id;




CREATE VIEW yieldsview_private AS
        SELECT
                CAST('yields' AS VARCHAR(10)) AS result_type,
                yields.id AS id,
                yields.citation_id,
                yields.site_id,
                yields.treatment_id,
                sites.sitename,
                sites.city,
                ST_Y(ST_CENTROID(sites.geometry)) AS lat,
                ST_X(ST_CENTROID(sites.geometry)) AS lon,
                species.scientificname,
                species.commonname,
                species.genus,
                species.id AS species_id,
                yields.cultivar_id,
                citations.author AS author,
                citations.year AS citation_year,
                treatments.name AS treatment,
                yields.date,
                extract(month from yields.date) AS month,
                extract(year from yields.date) AS year,
                yields.dateloc,
                variables.name AS trait,
                variables.description AS trait_description,
                yields.mean,
                variables.units,
                yields.n,
                yields.statname,
                yields.stat,
                yields.notes,
                yields.access_level,
                yields.checked,
                users.login,
                users.name,
                users.email
       FROM
                          yields
                LEFT JOIN sites ON yields.site_id = sites.id
                LEFT JOIN species ON yields.specie_id = species.id
                LEFT JOIN citations ON yields.citation_id = citations.id
                LEFT JOIN treatments ON yields.treatment_id = treatments.id
                LEFT JOIN variables ON variables.name = 'Ayield'
                LEFT JOIN users ON yields.user_id = users.id;



CREATE VIEW traits_and_yields_view_private AS
        SELECT * FROM traitsview_private
            UNION ALL              /* UNION ALL is more efficient and (here) it is equal to UNION */
        SELECT * FROM yieldsview_private;


CREATE VIEW traits_and_yields_view AS
        SELECT
                result_type,
                id,
                citation_id,
                site_id,
                treatment_id,
                sitename,
                city,
                lat,
                lon,
                scientificname,
                commonname,
                genus,
                species_id,
                cultivar_id,
                author,
                citation_year,
                treatment,
                date,
                month,
                year,
                dateloc,
                trait,
                trait_description,
                mean,
                units,
                n,
                statname,
                stat,
                notes,
                access_level
       FROM
                traits_and_yields_view_private
       WHERE
                checked > 0;
    }



  end

  def self.down
  end
end
