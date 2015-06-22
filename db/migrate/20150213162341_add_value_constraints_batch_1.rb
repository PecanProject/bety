class AddValueConstraintsBatch1 < ActiveRecord::Migration
  def self.up

    # Use "%q" so that backspashes are taken literally (except when doubled).
    execute %q{

/* Need to drop and later re-create views that depend on columns whose type we are changing. */
DROP VIEW IF EXISTS traits_and_yields_view;
DROP VIEW IF EXISTS traits_and_yields_view_private;
DROP VIEW IF EXISTS yieldsview_private;
DROP VIEW IF EXISTS traitsview_private;


CREATE OR REPLACE FUNCTION utc_now()
    RETURNS timestamp AS $$
BEGIN
    RETURN CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_whitespace_free(
    string text
) RETURNS boolean AS $$
BEGIN
    RETURN string !~ '[\s\u00a0]';
END;
$$ LANGUAGE plpgsql;



 /* This function documents how the regular expressions names 'host', 'URI', and
 'EMAIL' used in the functions 'is_host_address', 'is_url_or_empty', and
 'is_wellformed_email' are built up from shorter expressions.  The names (except
 with '_' replacing '-'), and except as noted, the definitions of these
 expressions are taken from Appendix A of RFC 3986.  (See
 http://tools.ietf.org/html/rfc3986#appendix-A.  A previous iteration of these
 expressions used http://www.w3.org/Addressing/URL/5_BNF.html as a guide.)

 The dependency structure of these definitions is roughly indicated by the
 indentation: in general, each definition directly depends on definitions above
 it having one level greater indentation. */
 
 /*
CREATE OR REPLACE FUNCTION generate_regexps() RETURNS void AS $body$
 DECLARE
     scheme text := '(https?|HTTPS?|ftp|FTP)'; -- These schemes should suffice for our purposes.
                      dec_octet text := '(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])';
                  IPv4address text := FORMAT('%s(\.%s){3}', dec_octet, dec_octet);
                      unreserved text := '[\w.~-]';
                          HEXDIG text := '[[:xdigit:]]';
                      pct_encoded text := FORMAT('%%%s%s', HEXDIG, HEXDIG);
                      sub_delims text := $$[!$&'()*+,;=]$$;
                  reg_name text := FORMAT('(%s|%s|%s)+', unreserved, pct_encoded, sub_delims); -- We disallow empty hosts.
              host text := FORMAT('(%s|%s)', IPv4address, reg_name); -- We're not allowing IPv6 for now.
              port text := '\d*';
          authority text := FORMAT('%s(:%s)?', host, port); -- We're not allowing authorities with a userinfo component.
                  pchar text := FORMAT('(%s|%s|%s|[:@])', unreserved, pct_encoded, sub_delims);
              segment text := FORMAT('%s*', pchar);
          path_abempty text := FORMAT('(/%s)*', segment);
      hier_part text := FORMAT('//%s%s', authority, path_abempty); -- We're only allowing URIs containing an authority.
      query text := FORMAT('(%s|[/?])*', pchar);
      fragment text := query;
    URI text := FORMAT('%s:%s(\?%s)?(#%s)?', scheme, hier_part, query, fragment);
    EMAIL text := FORMAT('%s+@%s', pchar, reg_name);
BEGIN
    RAISE NOTICE 'host: %', host; -- REMOVE THIS!!!!
    RAISE NOTICE 'URI: %', URI;
    RAISE NOTICE 'EMAIL: %', EMAIL;
END;
$body$ LANGUAGE plpgsql;
*/

CREATE OR REPLACE FUNCTION is_host_address(
  string text
) RETURNS boolean AS $body$
DECLARE
    host text := $$ # use expanded syntax
                   (
                       # the IPv4address form of specifying a host 
                       (\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])        # a decimal octet
                       (\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])){3} # three more decimal octets preceded by dots
                   |
                       # named hosts
                       (
                           [\w.~-] # unreserved characters
                       |
                           %[[:xdigit:]][[:xdigit:]] # percent-escaped characters
                       |
                           [!$&'()*+,;=] # gen-delims
                       )+
                   )$$;
BEGIN
    /* The '(?x)' must go here because we are prefixing the value of "host" with a '^'. */
    RETURN (string ~ ('(?x)^' || host || '$'));
END;
$body$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION is_url_or_empty(
  string text
) RETURNS boolean AS $body$
DECLARE
    URI text := $$ # use expanded syntax
                  (https?|HTTPS?|ftp|FTP): # scheme (restricted)
                  //
                  (
                      # the IPv4address form of specifying a host 
                      (\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])
                      (\.(\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])){3}
                  |
                      # named hosts
                      (
                          [\w.~-] # unreserved characters
                      |
                          %[[:xdigit:]][[:xdigit:]] # percent-escaped characters
                      |
                          [!$&'()*+,;=]
                      )+
                  )
                  (:\d*)? # optional port number
                  (
                      # path
                      /
                      (
                          [\w.~-] # unreserved characters
                      |
                          %[[:xdigit:]][[:xdigit:]] # percent-escaped characters
                      |
                          [!$&'()*+,;=] # gen-delims
                      |
                          [:@] # additional path characters
                      )*
                  )*
                  (
                      # optional query string
                      \?
                      (
                          (
                              [\w.~-] # unreserved characters
                          |
                              %[[:xdigit:]][[:xdigit:]] # percent-escaped characters
                          |
                              [!$&'()*+,;=] # gen-delims
                          |
                              [:@] # additional pchars
                          )
                      |
                          [/?] # additional query string characters
                      )*
                  )?
                  (
                      # optional fragment
                      \#
                      (
                          (
                              [\w.~-] # unreserved characters
                          |
                              %[[:xdigit:]][[:xdigit:]] # percent-escaped characters
                          |
                              [!$&'()*+,;=] # gen-delims
                          |
                              [:@] # additional pchars
                          )
                      |
                          [/?] # additional fragment characters
                      )*
                  )?
                $$;
BEGIN
    /* The '(?x)' must go here because we are prefixing the value of "URI" with a '^'. */
    RETURN (string ~ ('(?x)^' || URI || '$') OR string = '');
END;
$body$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_wellformed_email(
    string text
) RETURNS boolean AS $body$
DECLARE
    EMAIL text := $$ # use expanded syntax
                  # local part
                  (
                      [\w.~-] # unreserved characters
                  |
                      %[[:xdigit:]][[:xdigit:]] # percent-escaped characters
                  |
                      [!$&'()*+,;=] # gen-delims
                  |
                      [:@] # other allowed characters
                  )+
                  @
                  # domain
                  (
                      [\w.~-] # unreserved characters
                  |
                      %[[:xdigit:]][[:xdigit:]] # percent-escaped characters
                  |
                      [!$&'()*+,;=] # gen-delims
                  )+
$$;
BEGIN
    /* The '(?x)' must go here because we are prefixing the value of "EMAIL" with a '^'. */
    RETURN (string ~ ('(?x)^' || EMAIL || '$'));
END;
$body$ LANGUAGE plpgsql;
 



/* New Domains */

-- This is used by covariates, traits, and yields:
CREATE DOMAIN statnames AS TEXT CHECK (VALUE IN ('SD', 'SE', 'MSE', '95%CI', 'LSD', 'MSD', 'HSD', '')) DEFAULT '' NOT NULL;

-- This is used by inputs, traits, users, and yields:
CREATE DOMAIN level_of_access AS INTEGER CHECK (VALUE BETWEEN 1 AND 4) NOT NULL;



/* CITATIONS */

/* FIX */ --UPDATE citations SET author = normalize_whitespace(author) WHERE NOT is_whitespace_normalized(author);
ALTER TABLE citations ALTER COLUMN author SET NOT NULL,
                      ADD CONSTRAINT normalized_citation_authors CHECK (is_whitespace_normalized(author));

ALTER TABLE citations ALTER COLUMN year SET NOT NULL,
                      ADD CONSTRAINT citation_year_not_in_future CHECK (year <= EXTRACT(year FROM NOW()) + 1);
/* ALTER TABLE citations ADD CHECK (year > 1800); ??? */

/* FIX */ --UPDATE citations SET title = normalize_whitespace(title) WHERE NOT is_whitespace_normalized(title);
ALTER TABLE citations ALTER COLUMN title SET NOT NULL,
                      ADD CONSTRAINT normalized_citation_titles CHECK (is_whitespace_normalized(title));

/* FIX */ --UPDATE citations SET journal = normalize_whitespace(journal) WHERE NOT is_whitespace_normalized(journal);
ALTER TABLE citations ALTER COLUMN journal SET NOT NULL,
                      ALTER COLUMN journal SET DEFAULT '',
                      ADD CONSTRAINT normalized_citation_journals CHECK (is_whitespace_normalized(journal));

-- decide if vol = 0 is allowed
ALTER TABLE citations ADD CONSTRAINT non_negative_citation_volume_number CHECK (vol >= 0);

ALTER TABLE citations ALTER COLUMN pg SET NOT NULL,
                      ALTER COLUMN pg SET DEFAULT '';

-- Check that pg is either empty or is positive integer possibly followed by and
-- n-dash and another positive integer:
/* FIX */ --UPDATE citations SET pg = REGEXP_REPLACE(pg, '-', E'\u2013') WHERE pg ~ '-';
ALTER TABLE citations ADD CONSTRAINT well_formed_citation_page_spec CHECK (pg ~ '^([1-9]\d*(\u2013[1-9]\d*)?)?$');

ALTER TABLE citations ALTER COLUMN url SET NOT NULL,
                      ALTER COLUMN url SET DEFAULT '',
                      ADD CONSTRAINT well_formed_citation_url CHECK (is_url_or_empty(url) OR url ~ '^\(.+\)$');

ALTER TABLE citations ALTER COLUMN pdf SET NOT NULL,
                      ALTER COLUMN pdf SET DEFAULT '',
                      ADD CONSTRAINT well_formed_citation_pdf_url CHECK (is_url_or_empty(pdf) OR pdf ~ '^\(.+\)$');

ALTER TABLE citations ALTER COLUMN doi SET NOT NULL,
                      ALTER COLUMN doi SET DEFAULT '',
                      ADD CONSTRAINT well_formed_citation_doi CHECK (doi ~ '^(|10\.\d+(\.\d+)?/.+)$');




/* COVARIATES */

-- See GH #216:
/* ALTER TABLE covariates ALTER COLUMN trait_id SET NOT NULL; */
/* ALTER TABLE covariates ALTER COLUMN variable_id SET NOT NULL; */

ALTER TABLE covariates ADD CONSTRAINT positive_covariate_sample_size CHECK (n >= 1);

ALTER TABLE covariates ALTER COLUMN statname SET DATA TYPE statnames,
                       ALTER COLUMN statname SET DEFAULT ''; -- Rails 3.2 needs this set here.  It's not enough that the statnames domain has default ''.
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

ALTER TABLE dbfiles ADD CONSTRAINT valid_dbfile_md5_hash_value CHECK (md5 ~ '^([\da-z]{32})?$');
ALTER TABLE dbfiles ADD CONSTRAINT valid_dbfile_container_type CHECK (container_type IN ('Model','Posterior','Input'));
-- consistency checks between this table and inputs, models, and posteriors tables are part of a separate migration


/* ENSEMBLES */

ALTER TABLE ensembles ALTER COLUMN notes SET NOT NULL,
                      ALTER COLUMN notes SET DEFAULT '';
ALTER TABLE ensembles ALTER COLUMN runtype SET NOT NULL,
                      ADD CONSTRAINT valid_ensemble_runtype CHECK (runtype IN ('ensemble', 'sensitivity analysis', 'MCMC', 'pda.emulator'));

/* ENTITIES */

ALTER TABLE entities ALTER COLUMN name SET NOT NULL,
                     ALTER COLUMN name SET DEFAULT '';
ALTER TABLE entities ADD CONSTRAINT normalized_entity_name CHECK (is_whitespace_normalized(name));
ALTER TABLE entities ALTER COLUMN notes SET NOT NULL,
                     ALTER COLUMN notes SET DEFAULT '';


/* FORMATS */

ALTER TABLE formats ALTER COLUMN dataformat SET NOT NULL,
                    ALTER COLUMN dataformat SET DEFAULT '';
ALTER TABLE formats ALTER COLUMN notes SET NOT NULL,
                    ALTER COLUMN notes SET DEFAULT '';
ALTER TABLE formats ALTER COLUMN name SET NOT NULL,
                    ADD CONSTRAINT normalized_format_name CHECK (is_whitespace_normalized(name));
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
                   ALTER COLUMN notes SET DEFAULT '';

-- see violators of potential not null constraints:
-- SELECT start_date, end_date FROM inputs WHERE start_date IS NULL OR end_date IS NULL;
/* ALTER TABLE inputs ALTER COLUMN start_date SET NOT NULL; */
/* ALTER TABLE inputs ALTER COLUMN end_date SET NOT NULL; */
-- see violators of CHECK (start_date < end_date):
-- SELECT start_date, end_date FROM inputs WHERE start_date >= end_date;
/* ALTER TABLE inputs ADD CHECK (start_date < end_date); */
-- see future dates:
-- SELECT start_date, end_date FROM inputs WHERE start_date > utc_now() OR end_date > utc_now();
/* ALTER TABLE inputs CHECK (end_date < utc_now()); */

ALTER TABLE inputs ALTER COLUMN name SET NOT NULL,
                   ADD CONSTRAINT normalized_input_name CHECK (is_whitespace_normalized(name));
ALTER TABLE inputs ALTER COLUMN access_level SET DATA TYPE level_of_access,
                   ALTER COLUMN access_level SET DEFAULT 4;

-- add after cleanup:
/* ALTER TABLE inputs ALTER COLUMN format_id SET NOT NULL; */

/* LIKELIHOODS */

-- no current constraints other than those in AddUniquenessConstraints migration


/* MACHINES */

ALTER TABLE machines ADD CONSTRAINT well_formed_machine_hostname CHECK (is_host_address(hostname));
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
ALTER TABLE methods ADD CONSTRAINT normalized_method_name CHECK (is_whitespace_normalized(name));
ALTER TABLE methods ALTER COLUMN description SET NOT NULL;
-- Additional constraints will be added when candidate key is implemented.


/* MIMETYPES */

-- Constraints are in AddUniquenessConstraints migration.


/* MODELS */

ALTER TABLE models ALTER COLUMN model_name SET NOT NULL,
                   ADD CONSTRAINT no_spaces_in_model_name CHECK (is_whitespace_free(model_name));
ALTER TABLE models ALTER COLUMN revision SET NOT NULL,
                   ADD CONSTRAINT normalized_revision_specifier CHECK (is_whitespace_normalized(revision));


/* MODELTYPES */

ALTER TABLE modeltypes ADD CONSTRAINT no_spaces_in_modeltype_name CHECK (is_whitespace_free(name));


/* MODELTYPES_FORMATS */

ALTER TABLE modeltypes_formats ADD CONSTRAINT valid_modeltype_format_tag CHECK (tag ~ '^[a-z]+$');
ALTER TABLE modeltypes_formats ALTER COLUMN required SET NOT NULL;
ALTER TABLE modeltypes_formats ALTER COLUMN input SET NOT NULL;


/* PFTS */

ALTER TABLE pfts ALTER COLUMN definition SET NOT NULL;
ALTER TABLE pfts ADD CONSTRAINT normalized_pft_name CHECK (is_whitespace_normalized(name));
ALTER TABLE pfts ALTER COLUMN pft_type SET NOT NULL,
                 ADD CONSTRAINT valid_pft_type CHECK (pft_type IN ('plant', 'cultivar', ''));

/* PRIORS */

ALTER TABLE priors ALTER COLUMN variable_id SET NOT NULL;
ALTER TABLE priors ALTER COLUMN phylogeny SET NOT NULL,
                   ADD CONSTRAINT normalized_prior_phylogeny_specifier CHECK (is_whitespace_normalized(phylogeny));
ALTER TABLE priors ALTER COLUMN distn SET NOT NULL,
                   ADD CONSTRAINT valid_prior_distn CHECK (distn IN ('beta', 'binom', 'cauchy', 'chisq', 'exp', 'f', 'gamma', 'geom', 'hyper', 'lnorm', 'logis', 'nbinom', 'norm', 'pois', 't', 'unif', 'weibull', 'wilcox'));
ALTER TABLE priors ALTER COLUMN parama SET NOT NULL;
ALTER TABLE priors ADD CONSTRAINT nonnegative_prior_sample_size CHECK (n >= 0);

/* PROJECTS */

ALTER TABLE projects ALTER COLUMN name SET NOT NULL,
                     ADD CONSTRAINT normalized_project_name CHECK (is_whitespace_normalized(name));
ALTER TABLE projects ALTER COLUMN outdir SET NOT NULL;
ALTER TABLE projects ALTER COLUMN description SET NOT NULL;


/* RUNS */

ALTER TABLE runs ALTER COLUMN outdir SET NOT NULL,
                 ALTER COLUMN outdir SET DEFAULT '';
ALTER TABLE runs ALTER COLUMN outprefix SET NOT NULL,
                 ALTER COLUMN outprefix SET DEFAULT '';
ALTER TABLE runs ALTER COLUMN setting SET NOT NULL,
                 ALTER COLUMN setting SET DEFAULT '';
-- ALTER TABLE runs ALTER COLUMN started_at SET NOT NULL;
-- ALTER TABLE runs ADD CONSTRAINT valid_run_start_time CHECK (started_at <= NOW()::timestamp); -- NOW()::timestamp makes clear we are using local machine time
-- ALTER TABLE runs ADD CONSTRAINT consistent_run_start_and_end_times CHECK (started_at <= finished_at AND finished_at <= NOW()::timestamp);
COMMENT ON COLUMN runs.started_at IS 'system time when run was started';

/* SITES */

ALTER TABLE sites ALTER COLUMN city SET NOT NULL,
                  ALTER COLUMN city SET DEFAULT '',
                  ADD CONSTRAINT normalized_site_city_name CHECK (is_whitespace_normalized(city));
ALTER TABLE sites ALTER COLUMN state SET NOT NULL,
                  ALTER COLUMN state SET DEFAULT '',
                  ADD CONSTRAINT normalized_site_state_name CHECK (is_whitespace_normalized(state));
ALTER TABLE sites ALTER COLUMN country SET NOT NULL,
                  ALTER COLUMN country SET DEFAULT '',
                  ADD CONSTRAINT normalized_site_country_name CHECK (is_whitespace_normalized(country));
ALTER TABLE sites ADD CONSTRAINT valid_site_mat_value CHECK (mat BETWEEN -25 AND 40);
ALTER TABLE sites ADD CONSTRAINT valid_site_map_value CHECK (map BETWEEN 0 AND 12000);
ALTER TABLE sites ALTER COLUMN soil SET NOT NULL,
                  ALTER COLUMN soil SET DEFAULT '';
-- see bad soil values:
--   SELECT id, soil FROM sites WHERE NOT soil IN ('clay', 'sandy clay', 'sandy clay loam', 'sandy loam', 'loamy sand', 'sand', 'clay loam', 'loam', 'silty clay', 'silty clay loam', 'silt loam', 'silt', '') ORDER BY id;
/* ALTER TABLE sites ADD CONSTRAINT valid_site_soil_specifier CHECK (soil IN ('clay', 'sandy clay', 'sandy clay loam', 'sandy loam', 'loamy sand', 'sand', 'clay loam', 'loam', 'silty clay', 'silty clay loam', 'silt loam', 'silt', '')); */
ALTER TABLE sites ADD CONSTRAINT valid_site_som_value CHECK (som BETWEEN 0 AND 100);
ALTER TABLE sites ALTER COLUMN notes SET NOT NULL,
                  ALTER COLUMN notes SET DEFAULT '';
ALTER TABLE sites ALTER COLUMN soilnotes SET NOT NULL,
                  ALTER COLUMN soilnotes SET DEFAULT '';
ALTER TABLE sites ALTER COLUMN sitename SET NOT NULL,
                  ADD CONSTRAINT normalized_site_sitename CHECK (is_whitespace_normalized(sitename));
ALTER TABLE sites ADD CONSTRAINT valid_site_sand_and_clay_percentage_values CHECK (sand_pct >= 0 AND clay_pct >= 0 AND sand_pct <= 100 AND clay_pct <= 100 AND sand_pct + clay_pct <= 100);
ALTER TABLE sites ADD CONSTRAINT valid_site_geometry_specification CHECK ( (ST_X(ST_CENTROID(geometry)) BETWEEN -180 AND 180) AND (ST_Y(ST_CENTROID(geometry)) BETWEEN -90 AND 90) AND (ST_Z(ST_CENTROID(geometry)) BETWEEN -418 AND 8848) );


/* SPECIES */

ALTER TABLE species ADD CONSTRAINT valid_species_spcd_value CHECK (spcd BETWEEN 0 AND 10000);

-- genus should consist of a capital letter followed by zero or more lower case letters or hyphens or be empty.
ALTER TABLE species ALTER COLUMN genus SET NOT NULL,
                    ALTER COLUMN genus SET DEFAULT '',
                    ADD CONSTRAINT valid_genus_name CHECK (genus ~ '^([A-Z][-a-z]*)?$');

-- species should be zero or more space-or-hyphen-separated groups of capital
-- letters followed by a period, sequences of two or more letters possibly
-- followed by a period, ampersands, and times symbols.
ALTER TABLE species ALTER COLUMN species SET NOT NULL,
                    ALTER COLUMN species SET DEFAULT '',
                    ADD CONSTRAINT valid_species_designation CHECK (species ~ '^(([A-Z]\.|[a-zA-Z]{2,}\.?|&|\u00d7)( |-|$))*$');

-- see rows that violate proposed consistency constraint:
--   SELECT scientificname, genus, species FROM species WHERE scientificname !~ FORMAT('^%s.*%s', genus, species);
-- scientificname should contain the genus followed by the species, possibly with one or more intervening characters.
ALTER TABLE species ALTER COLUMN scientificname SET NOT NULL,
                    ADD CONSTRAINT normalized_species_scientificname CHECK (is_whitespace_normalized(scientificname))/*,
                    ADD CONSTRAINT mutually_consistent_genus_species_and_scientificname CHECK (scientificname ~ FORMAT('%s.*%s', genus, species))*/;

ALTER TABLE species ALTER COLUMN commonname SET NOT NULL,
                    ALTER COLUMN commonname SET DEFAULT '',
                    ADD CONSTRAINT normalized_species_commonname CHECK (is_whitespace_normalized(commonname));
ALTER TABLE species ALTER COLUMN notes SET NOT NULL,
                    ALTER COLUMN notes SET DEFAULT '';

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

ALTER TABLE traits ALTER COLUMN statname SET DATA TYPE statnames,
                   ALTER COLUMN statname SET DEFAULT ''; -- Rails 3.2 needs this set here.  It's not enough that the statnames domain has default ''.

-- see species-cultivar inconsistencies:
--   SELECT t_sp.scientificname AS "species referred to by traits table", c_sp.scientificname AS "species matching cultivar", c.name FROM traits t JOIN cultivars c ON t.cultivar_id = c.id JOIN species t_sp ON t_sp.id = t.specie_id JOIN species c_sp ON c.specie_id = c_sp.id WHERE t.specie_id != c.specie_id;
-- decide on consistency constraint
ALTER TABLE traits ALTER COLUMN notes SET NOT NULL,
                   ALTER COLUMN notes SET DEFAULT '';
/* ALTER TABLE traits ALTER COLUMN checked SET NOT NULL; */
ALTER TABLE traits ADD CONSTRAINT valid_trait_checked_value CHECK (checked BETWEEN -1 AND 1);
-- add after cleaning up rows where access_level = 0; may need to drop and re-add dependent views before doing this:
/* ALTER TABLE traits ALTER COLUMN access_level SET DATA TYPE level_of_access; */

-- see count of NULLs in proposed key columns:
--   SELECT COUNT(*) AS "total number of rows", SUM((site_id IS NULL)::int) AS "site_id NULLs", SUM((specie_id IS NULL)::int) AS "species_id NULLs", SUM((citation_id IS NULL)::int) AS "citation_id NULLs", SUM((cultivar_id IS NULL)::int) AS "cultivar_id NULLs", SUM((treatment_id IS NULL)::int) AS "treatment_id NULLs", SUM((date IS NULL)::int) AS "date NULLs", SUM((time IS NULL)::int) AS "time NULLs", SUM((variable_id IS NULL)::int) AS "variable_id NULLs", SUM((entity_id IS NULL)::int) AS "entity_id NULLs", SUM((method_id IS NULL)::int) AS "method_id NULLs", SUM((date_year IS NULL)::int) AS "date_year NULLs", SUM((date_month IS NULL)::int) AS "date_month NULLs", SUM((date_day IS NULL)::int) AS "date_day NULLs", SUM((time_hour IS NULL)::int) AS "time_hour NULLs", SUM((time_minute)::int) AS "time_minute" FROM traits;
-- more info about missing date and time info:
--   SELECT COUNT(*) AS "total number of rows", SUM((date IS NULL AND date_year IS NULL AND date_month IS NULL AND date_day IS NULL)::int) AS "rows with no date info", SUM((time IS NULL AND time_hour IS NULL AND time_minute IS NULL)::int) AS "rows with no time into" FROM traits;


/* TREATMENTS */

ALTER TABLE treatments ALTER COLUMN name SET NOT NULL;
/* FIX */ --UPDATE treatments SET name = normalize_whitespace(name) WHERE NOT is_whitespace_normalized(name);
ALTER TABLE treatments ADD CONSTRAINT normalized_treatment_name CHECK (is_whitespace_normalized(name));
ALTER TABLE treatments ALTER COLUMN definition SET NOT NULL,
                       ALTER COLUMN definition SET DEFAULT '',
                       ADD CONSTRAINT normalized_treatment_definition CHECK (is_whitespace_normalized(definition));


/* USERS */

ALTER TABLE users ALTER COLUMN login SET NOT NULL;
ALTER TABLE users ADD CONSTRAINT valid_user_login CHECK (login ~ '^[a-z\d_][a-z\d_.@-]{2,39}$'); -- matches Rails app requirements
ALTER TABLE users ALTER COLUMN name SET NOT NULL,
                  ALTER COLUMN name SET DEFAULT '';
ALTER TABLE users ADD CONSTRAINT normalized_user_name CHECK (is_whitespace_normalized(name));
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
ALTER TABLE users ADD CONSTRAINT well_formed_user_email CHECK (is_wellformed_email(email));
ALTER TABLE users ALTER COLUMN city SET NOT NULL,
                  ALTER COLUMN city SET DEFAULT '';
/* FIX */ --UPDATE users SET city = normalize_whitespace(city) WHERE NOT is_whitespace_normalized(city);
ALTER TABLE users ADD CONSTRAINT normalized_user_city_name CHECK (is_whitespace_normalized(city));
ALTER TABLE users ALTER COLUMN country SET NOT NULL,
                  ALTER COLUMN country SET DEFAULT '';
ALTER TABLE users ADD CONSTRAINT normalized_user_country_name CHECK (is_whitespace_normalized(country));
ALTER TABLE users ALTER COLUMN crypted_password SET NOT NULL;
ALTER TABLE users ADD CONSTRAINT valid_user_crypted_password_value CHECK (crypted_password ~ '^[0-9a-f]{1,40}$');
/* ALTER TABLE users ALTER COLUMN salt SET NOT NULL; */
ALTER TABLE users ALTER COLUMN access_level SET DATA TYPE level_of_access;
ALTER TABLE users ALTER COLUMN page_access_level SET DATA TYPE level_of_access;
/* FIX */ --UPDATE users SET apikey = '' WHERE apikey IS NULL;
ALTER TABLE users ADD CONSTRAINT valid_user_apikey_value CHECK (apikey ~ '^[0-9a-zA-Z+/]{40}$');
ALTER TABLE users ALTER COLUMN state_prov SET NOT NULL,
                  ALTER COLUMN state_prov SET DEFAULT '',
                  ADD CONSTRAINT normalized_stat_prov_name CHECK (is_whitespace_normalized(state_prov));
ALTER TABLE users ALTER COLUMN postal_code SET NOT NULL,
                  ALTER COLUMN postal_code SET DEFAULT '',
                  ADD CONSTRAINT normalized_postal_code CHECK (is_whitespace_normalized(postal_code));


/* VARIABLES */

/* Use this function to check numericality of min and max until and unless those
columns are changed to a numeric type. */
CREATE OR REPLACE FUNCTION is_numerical(text) RETURNS BOOLEAN AS $$
DECLARE x FLOAT;
BEGIN
   /* We attempt to cast to FLOAT rather than NUMERIC because we want 'INFINITY'
      and '-INFINITY' to count as being numerical. */
    x = $1::FLOAT;
    RETURN TRUE;
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

/* FIX */ --UPDATE variables SET description = normalize_whitespace(description) WHERE NOT is_whitespace_normalized(description);
ALTER TABLE variables ALTER COLUMN description SET NOT NULL,
                      ALTER COLUMN description SET DEFAULT '',
                      ADD CONSTRAINT normalized_variable_description CHECK (is_whitespace_normalized(description));
ALTER TABLE variables ALTER COLUMN units SET NOT NULL,
                      ALTER COLUMN units SET DEFAULT '',
                      ADD CONSTRAINT normalized_variable_units_specifier CHECK (is_whitespace_normalized(units));
/* FIX */ --UPDATE VARIABLES SET notes = '' WHERE notes IS NULL;
ALTER TABLE variables ALTER COLUMN notes SET NOT NULL,
                      ALTER COLUMN notes SET DEFAULT '';
ALTER TABLE variables ALTER COLUMN name SET NOT NULL,
                      ADD CONSTRAINT normalized_variable_name CHECK (is_whitespace_normalized(name));
/* FIX */ --UPDATE variables SET max = 'Infinity', min = '-Infinity' WHERE (max IS NULL OR max = '') AND (min IS NULL OR min = '');
/* FIX */ --UPDATE variables SET max = 'Infinity' WHERE max IS NULL OR max = '';
/* FIX */ --UPDATE variables SET min = '-Infinity' WHERE min IS NULL OR min = '';
ALTER TABLE variables ALTER COLUMN max SET NOT NULL,
                      ALTER COLUMN max SET DEFAULT 'Infinity',
                      ADD CONSTRAINT variable_max_is_a_number CHECK (is_numerical(max));
ALTER TABLE variables ALTER COLUMN min SET NOT NULL,
                      ALTER COLUMN min SET DEFAULT '-Infinity',
                      ADD CONSTRAINT variable_min_is_a_number CHECK (is_numerical(min));
ALTER TABLE variables ADD CONSTRAINT variable_min_is_less_than_max CHECK (min::float <= max::float);


/* WORKFLOWS */

ALTER TABLE workflows ALTER COLUMN folder SET NOT NULL;
ALTER TABLE workflows ADD CONSTRAINT normalized_workflow_folder_name CHECK (is_whitespace_normalized(folder));
ALTER TABLE workflows ALTER COLUMN hostname SET NOT NULL;
ALTER TABLE workflows ADD CONSTRAINT normalized_workflow_hostname CHECK (is_whitespace_normalized(hostname));
/* FIX */ --UPDATE workflows SET params = '' WHERE params IS NULL;
ALTER TABLE workflows ALTER COLUMN params SET NOT NULL,
                      ALTER COLUMN params SET DEFAULT '';
ALTER TABLE workflows ADD CONSTRAINT normalized_workflow_params_value CHECK (is_whitespace_normalized(params));
ALTER TABLE workflows ALTER COLUMN advanced_edit SET NOT NULL;


/* YIELDS */

ALTER TABLE yields ALTER COLUMN mean SET NOT NULL;
/* FIX */ --UPDATE yields SET statname = '' WHERE statname IS NULL;
ALTER TABLE yields ALTER COLUMN statname SET DATA TYPE statnames,
                   ALTER COLUMN statname SET DEFAULT ''; -- Rails 3.2 needs this set here.  It's not enough that the statnames domain has default ''.
/* FIX */ --UPDATE yields SET notes = '' WHERE notes IS NULL;
ALTER TABLE yields ALTER COLUMN notes SET NOT NULL,
                   ALTER COLUMN notes SET DEFAULT '';
ALTER TABLE yields ALTER COLUMN checked SET NOT NULL,
                   ADD CONSTRAINT valid_yield_checked_value CHECK (checked BETWEEN -1 AND 1);
ALTER TABLE yields ALTER COLUMN access_level SET DATA TYPE level_of_access;
-- see species-cultivar inconsistencies:
--   SELECT y_sp.scientificname AS "species referred to by yields table", c_sp.scientificname AS "species matching cultivar", c.name FROM yields y JOIN cultivars c ON y.cultivar_id = c.id JOIN species y_sp ON y_sp.id = y.specie_id JOIN species c_sp ON c.specie_id = c_sp.id WHERE y.specie_id != c.specie_id;





CREATE VIEW traitsview_private AS
        SELECT
                CAST('traits' AS CHAR(10)) AS result_type,
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
                CAST('yields' AS CHAR(10)) AS result_type,
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

################################################################################

  def self.down

    # Use "%q" so that backspashes are taken literally (except when doubled).
    execute %q{

/* Need to drop and later re-create views that depend on columns whose type we are changing. */
DROP VIEW IF EXISTS traits_and_yields_view;
DROP VIEW IF EXISTS traits_and_yields_view_private;
DROP VIEW IF EXISTS yieldsview_private;
DROP VIEW IF EXISTS traitsview_private;


DROP FUNCTION IF EXISTS utc_now();
DROP FUNCTION IF EXISTS is_whitespace_free(text) CASCADE;
DROP FUNCTION IF EXISTS is_host_address(text) CASCADE;


DROP FUNCTION IF EXISTS is_url_or_empty(text) CASCADE;

DROP FUNCTION IF EXISTS is_wellformed_email(text) CASCADE;
 


/* CITATIONS */

ALTER TABLE citations ALTER COLUMN author DROP NOT NULL,
                      DROP CONSTRAINT normalized_citation_authors;

ALTER TABLE citations ALTER COLUMN year DROP NOT NULL,
                      DROP CONSTRAINT citation_year_not_in_future;
ALTER TABLE citations ALTER COLUMN title DROP NOT NULL,
                      DROP CONSTRAINT normalized_citation_titles; 
ALTER TABLE citations ALTER COLUMN journal DROP NOT NULL,
                      ALTER COLUMN journal DROP DEFAULT,
                      DROP CONSTRAINT normalized_citation_journals;
ALTER TABLE citations DROP CONSTRAINT non_negative_citation_volume_number;

ALTER TABLE citations ALTER COLUMN pg DROP NOT NULL,
                      ALTER COLUMN pg DROP DEFAULT;

ALTER TABLE citations DROP CONSTRAINT well_formed_citation_page_spec;

ALTER TABLE citations ALTER COLUMN url DROP NOT NULL,
                      ALTER COLUMN url DROP DEFAULT;

ALTER TABLE citations ALTER COLUMN pdf DROP NOT NULL,
                      ALTER COLUMN pdf DROP DEFAULT;

ALTER TABLE citations ALTER COLUMN doi DROP NOT NULL,
                      ALTER COLUMN doi DROP DEFAULT,
                      DROP CONSTRAINT well_formed_citation_doi; 




/* COVARIATES */

ALTER TABLE covariates DROP CONSTRAINT positive_covariate_sample_size;

ALTER TABLE covariates ALTER COLUMN statname SET DATA TYPE VARCHAR(255),
                       ALTER COLUMN statname DROP DEFAULT;

/* CULTIVARS */

ALTER TABLE cultivars ALTER COLUMN ecotype DROP NOT NULL,
                      ALTER COLUMN ecotype DROP DEFAULT;
ALTER TABLE cultivars ALTER COLUMN notes DROP NOT NULL,
                      ALTER COLUMN notes DROP DEFAULT;


/* DBFILES */

ALTER TABLE dbfiles DROP CONSTRAINT valid_dbfile_md5_hash_value;
ALTER TABLE dbfiles DROP CONSTRAINT valid_dbfile_container_type;

/* ENSEMBLES */

ALTER TABLE ensembles ALTER COLUMN notes DROP NOT NULL,
                      ALTER COLUMN notes DROP DEFAULT;
ALTER TABLE ensembles ALTER COLUMN runtype DROP NOT NULL,
                      DROP CONSTRAINT valid_ensemble_runtype; 

/* ENTITIES */

ALTER TABLE entities ALTER COLUMN name DROP NOT NULL,
                     ALTER COLUMN name DROP DEFAULT;
ALTER TABLE entities DROP CONSTRAINT normalized_entity_name;
ALTER TABLE entities ALTER COLUMN notes DROP NOT NULL,
                     ALTER COLUMN notes DROP DEFAULT;


/* FORMATS */

ALTER TABLE formats ALTER COLUMN dataformat DROP NOT NULL,
                    ALTER COLUMN dataformat DROP DEFAULT;
ALTER TABLE formats ALTER COLUMN notes DROP NOT NULL,
                    ALTER COLUMN notes DROP DEFAULT;
ALTER TABLE formats ALTER COLUMN name DROP NOT NULL,
                    DROP CONSTRAINT normalized_format_name;
ALTER TABLE formats ALTER COLUMN header DROP NOT NULL,
                    ALTER COLUMN header DROP DEFAULT;
ALTER TABLE formats ALTER COLUMN skip DROP NOT NULL,
                    ALTER COLUMN skip DROP DEFAULT;


/* FORMATS_VARIABLES */

ALTER TABLE formats_variables ALTER COLUMN format_id DROP NOT NULL;
ALTER TABLE formats_variables ALTER COLUMN variable_id DROP NOT NULL;
ALTER TABLE formats_variables ALTER COLUMN name DROP NOT NULL,
                              ALTER COLUMN name DROP DEFAULT;
ALTER TABLE formats_variables ALTER COLUMN unit DROP NOT NULL,
                              ALTER COLUMN unit DROP DEFAULT;
ALTER TABLE formats_variables ALTER COLUMN storage_type DROP NOT NULL,
                              ALTER COLUMN storage_type DROP DEFAULT;

/* INPUTS */

ALTER TABLE inputs ALTER COLUMN notes DROP NOT NULL,
                   ALTER COLUMN notes DROP DEFAULT;

ALTER TABLE inputs ALTER COLUMN name DROP NOT NULL,
                   DROP CONSTRAINT normalized_input_name;
ALTER TABLE inputs ALTER COLUMN access_level SET DATA TYPE integer,
                   ALTER COLUMN access_level DROP DEFAULT;


/* MANAGEMENTS */

ALTER TABLE managements ALTER COLUMN mgmttype DROP NOT NULL;
ALTER TABLE managements ALTER COLUMN notes DROP NOT NULL,
                        ALTER COLUMN notes DROP DEFAULT;


/* METHODS */

ALTER TABLE methods ALTER COLUMN name DROP NOT NULL;
ALTER TABLE methods DROP CONSTRAINT normalized_method_name;
ALTER TABLE methods ALTER COLUMN description DROP NOT NULL;

/* MODELS */

ALTER TABLE models ALTER COLUMN model_name DROP NOT NULL;
ALTER TABLE models ALTER COLUMN revision DROP NOT NULL;


/* MODELTYPES_FORMATS */

ALTER TABLE modeltypes_formats DROP CONSTRAINT valid_modeltype_format_tag; 
ALTER TABLE modeltypes_formats ALTER COLUMN required DROP NOT NULL;
ALTER TABLE modeltypes_formats ALTER COLUMN input DROP NOT NULL;


/* PFTS */

ALTER TABLE pfts ALTER COLUMN definition DROP NOT NULL;
ALTER TABLE pfts DROP CONSTRAINT normalized_pft_name;
ALTER TABLE pfts ALTER COLUMN pft_type DROP NOT NULL,
                 DROP CONSTRAINT valid_pft_type;

/* PRIORS */

ALTER TABLE priors ALTER COLUMN variable_id DROP NOT NULL;
ALTER TABLE priors ALTER COLUMN phylogeny DROP NOT NULL,
                   DROP CONSTRAINT normalized_prior_phylogeny_specifier; 
ALTER TABLE priors ALTER COLUMN distn DROP NOT NULL,
                   DROP CONSTRAINT valid_prior_distn;
ALTER TABLE priors ALTER COLUMN parama DROP NOT NULL;
ALTER TABLE priors DROP CONSTRAINT nonnegative_prior_sample_size; 

/* PROJECTS */

ALTER TABLE projects ALTER COLUMN name DROP NOT NULL,
                     DROP CONSTRAINT normalized_project_name;
ALTER TABLE projects ALTER COLUMN outdir DROP NOT NULL;
ALTER TABLE projects ALTER COLUMN description DROP NOT NULL;


/* RUNS */

ALTER TABLE runs ALTER COLUMN outdir DROP NOT NULL,
                 ALTER COLUMN outdir DROP DEFAULT;
ALTER TABLE runs ALTER COLUMN outprefix DROP NOT NULL,
                 ALTER COLUMN outprefix DROP DEFAULT;
ALTER TABLE runs ALTER COLUMN setting DROP NOT NULL,
                 ALTER COLUMN setting DROP DEFAULT;
-- ALTER TABLE runs ALTER COLUMN started_at DROP NOT NULL;
-- ALTER TABLE runs DROP CONSTRAINT valid_run_start_time;
-- ALTER TABLE runs DROP CONSTRAINT consistent_run_start_and_end_times; 
COMMENT ON COLUMN runs.started_at IS 'system time when run begins';

/* SITES */

ALTER TABLE sites ALTER COLUMN city DROP NOT NULL,
                  ALTER COLUMN city DROP DEFAULT;
ALTER TABLE sites ALTER COLUMN state DROP NOT NULL,
                  ALTER COLUMN state DROP DEFAULT;
ALTER TABLE sites ALTER COLUMN country DROP NOT NULL,
                  ALTER COLUMN country DROP DEFAULT;
ALTER TABLE sites DROP CONSTRAINT valid_site_mat_value;
ALTER TABLE sites DROP CONSTRAINT valid_site_map_value;
ALTER TABLE sites ALTER COLUMN soil DROP NOT NULL,
                  ALTER COLUMN soil DROP DEFAULT;
ALTER TABLE sites DROP CONSTRAINT valid_site_som_value;
ALTER TABLE sites ALTER COLUMN notes DROP NOT NULL,
                  ALTER COLUMN notes DROP DEFAULT;
ALTER TABLE sites ALTER COLUMN soilnotes DROP NOT NULL,
                  ALTER COLUMN soilnotes DROP DEFAULT;
ALTER TABLE sites ALTER COLUMN sitename DROP NOT NULL;
ALTER TABLE sites DROP CONSTRAINT normalized_site_city_name;
ALTER TABLE sites DROP CONSTRAINT normalized_site_state_name;
ALTER TABLE sites DROP CONSTRAINT normalized_site_country_name;
ALTER TABLE sites DROP CONSTRAINT normalized_site_sitename;
ALTER TABLE sites DROP CONSTRAINT valid_site_sand_and_clay_percentage_values;
ALTER TABLE sites DROP CONSTRAINT valid_site_geometry_specification;


/* SPECIES */

ALTER TABLE species DROP CONSTRAINT valid_species_spcd_value;
ALTER TABLE species ALTER COLUMN genus DROP NOT NULL,
                    ALTER COLUMN genus DROP DEFAULT,
                    DROP CONSTRAINT valid_genus_name;
ALTER TABLE species ALTER COLUMN species DROP NOT NULL,
                    ALTER COLUMN species DROP DEFAULT,
                    DROP CONSTRAINT valid_species_designation;
ALTER TABLE species ALTER COLUMN scientificname DROP NOT NULL,
                    DROP CONSTRAINT normalized_species_scientificname;

ALTER TABLE species ALTER COLUMN commonname DROP NOT NULL,
                    ALTER COLUMN commonname DROP DEFAULT,
                    DROP CONSTRAINT normalized_species_commonname;
ALTER TABLE species ALTER COLUMN notes DROP NOT NULL,
                    ALTER COLUMN notes DROP DEFAULT;
DROP FUNCTION IF EXISTS replace_x() CASCADE;



/* TRAIT_COVARIATE_ASSOCIATIONS */

ALTER TABLE trait_covariate_associations ALTER COLUMN required DROP NOT NULL;


/* TRAITS */

ALTER TABLE traits ALTER COLUMN statname SET DATA TYPE VARCHAR(255),
                   ALTER COLUMN statname DROP DEFAULT;
ALTER TABLE traits ALTER COLUMN notes DROP NOT NULL,
                   ALTER COLUMN notes DROP DEFAULT;
ALTER TABLE traits DROP CONSTRAINT valid_trait_checked_value;

/* TREATMENTS */

ALTER TABLE treatments ALTER COLUMN name DROP NOT NULL;
ALTER TABLE treatments DROP CONSTRAINT normalized_treatment_name;
ALTER TABLE treatments ALTER COLUMN definition DROP NOT NULL,
                       ALTER COLUMN definition DROP DEFAULT,
                       DROP CONSTRAINT normalized_treatment_definition;


/* USERS */

ALTER TABLE users ALTER COLUMN login DROP NOT NULL;
ALTER TABLE users DROP CONSTRAINT valid_user_login;
ALTER TABLE users ALTER COLUMN name DROP NOT NULL;
ALTER TABLE users DROP CONSTRAINT normalized_user_name;
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;
ALTER TABLE users ALTER COLUMN city DROP NOT NULL,
                  ALTER COLUMN city DROP DEFAULT;
ALTER TABLE users DROP CONSTRAINT normalized_user_city_name;
ALTER TABLE users ALTER COLUMN country DROP NOT NULL,
                  ALTER COLUMN country DROP DEFAULT;
ALTER TABLE users DROP CONSTRAINT normalized_user_country_name;
ALTER TABLE users ALTER COLUMN crypted_password DROP NOT NULL;
ALTER TABLE users DROP CONSTRAINT valid_user_crypted_password_value;
ALTER TABLE users ALTER COLUMN access_level SET DATA TYPE integer;
ALTER TABLE users ALTER COLUMN page_access_level SET DATA TYPE integer;
ALTER TABLE users DROP CONSTRAINT valid_user_apikey_value;
ALTER TABLE users ALTER COLUMN state_prov DROP NOT NULL,
                  ALTER COLUMN state_prov DROP DEFAULT,
                  DROP CONSTRAINT normalized_stat_prov_name;
ALTER TABLE users ALTER COLUMN postal_code DROP NOT NULL,
                  ALTER COLUMN postal_code DROP DEFAULT,
                  DROP CONSTRAINT normalized_postal_code;


/* VARIABLES */

/* Use this function to check numericality of min and max until and unless those
columns are changed to a numeric type. */
DROP FUNCTION IF EXISTS is_numerical(text) CASCADE;
ALTER TABLE variables ALTER COLUMN description DROP NOT NULL,
                      ALTER COLUMN description DROP DEFAULT,
                      DROP CONSTRAINT normalized_variable_description;
ALTER TABLE variables ALTER COLUMN units DROP NOT NULL,
                      ALTER COLUMN units DROP DEFAULT,
                      DROP CONSTRAINT normalized_variable_units_specifier; 
ALTER TABLE variables ALTER COLUMN notes DROP NOT NULL,
                      ALTER COLUMN notes DROP DEFAULT;
ALTER TABLE variables ALTER COLUMN name DROP NOT NULL,
                      DROP CONSTRAINT normalized_variable_name;
ALTER TABLE variables ALTER COLUMN max DROP NOT NULL,
                      ALTER COLUMN max DROP DEFAULT;
ALTER TABLE variables ALTER COLUMN min DROP NOT NULL,
                      ALTER COLUMN min DROP DEFAULT;
ALTER TABLE variables DROP CONSTRAINT variable_min_is_less_than_max;


/* WORKFLOWS */

ALTER TABLE workflows ALTER COLUMN folder DROP NOT NULL;
ALTER TABLE workflows DROP CONSTRAINT normalized_workflow_folder_name;
ALTER TABLE workflows ALTER COLUMN hostname DROP NOT NULL;
ALTER TABLE workflows DROP CONSTRAINT normalized_workflow_hostname;
ALTER TABLE workflows ALTER COLUMN params DROP NOT NULL,
                      ALTER COLUMN params DROP DEFAULT;
ALTER TABLE workflows DROP CONSTRAINT normalized_workflow_params_value;
ALTER TABLE workflows ALTER COLUMN advanced_edit DROP NOT NULL;


/* YIELDS */

ALTER TABLE yields ALTER COLUMN mean DROP NOT NULL;
ALTER TABLE yields ALTER COLUMN statname DROP NOT NULL,
                   ALTER COLUMN statname DROP DEFAULT,
                   ALTER COLUMN statname SET DATA TYPE VARCHAR(255);
ALTER TABLE yields ALTER COLUMN notes DROP NOT NULL,
                   ALTER COLUMN notes DROP DEFAULT;
ALTER TABLE yields ALTER COLUMN checked DROP NOT NULL,
                   DROP CONSTRAINT valid_yield_checked_value;
ALTER TABLE yields ALTER COLUMN access_level SET DATA TYPE integer;




/* Drop New Domains */
DROP DOMAIN IF EXISTS statnames;
DROP DOMAIN IF EXISTS level_of_access;



/* Recreate Views */
CREATE VIEW traitsview_private AS
        SELECT
                CAST('traits' AS CHAR(10)) AS result_type,
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
                CAST('yields' AS CHAR(10)) AS result_type,
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
end
