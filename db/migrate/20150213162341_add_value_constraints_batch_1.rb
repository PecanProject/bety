class AddValueConstraintsBatch1 < ActiveRecord::Migration
  def self.up

    # Use "%q" so that backspashes are taken literally (except when doubled).
    execute %q{

/* THIS SECTION IS ONLY HERE TEMPORARILY! DELETE AFTER AddUniquenessConstraints MIGRATION IS ADDED! */
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

/* END OF TEMPORARY SECTION */

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


/* CITATIONS */

ALTER TABLE citations ALTER COLUMN author SET NOT NULL;
ALTER TABLE citations ADD CHECK (is_whitespace_normalized(author));
ALTER TABLE citations ALTER COLUMN year SET NOT NULL;
ALTER TABLE citations ALTER COLUMN title SET NOT NULL;
ALTER TABLE citations ADD CHECK (is_whitespace_normalized(title));
-- view NULLs in journal:
-- SELECT * FROM citations WHERE journal IS NULL;
-- clean up NULLs in journal:
-- UPDATE citations SET journal = '' WHERE journal IS NULL;
ALTER TABLE citations ALTER COLUMN journal SET NOT NULL;
-- view non-normalized journal values:
-- SELECT * FROM citations WHERE NOT is_whitespace_normalized(journal);
---- OR
__ SELECT '"'||journal||'"' FROM citations WHERE NOT is_whitespace_normalized(journal);
-- normalized whitespace in journal:
-- UPDATE citations SET journal = normalize_whitespace(journal) WHERE NOT is_whitespace_normalized(journal);
ALTER TABLE citations ADD CHECK (is_whitespace_normalized(journal));

-- decide if vol = 0 is allowed before adding this:
/* ALTER TABLE citations ADD CHECK (vol > 0); */

-- view NULLs in pg:
-- SELECT * FROM citations WHERE pg IS NULL;
-- clean up NULLs in pg:
-- UPDATE citations SET pg = '' WHERE pg IS NULL;
ALTER TABLE citations ALTER COLUMN pg SET NOT NULL;

-- decide if these constraints are ok:
/*
-- view problem pg values:
-- SELECT pg FROM citations WHERE pg !~ '^([1-9]\d*(\u2013[1-9]\d*)?)?$';
-- fix most values:
-- UPDATE citations SET pg = regexp_replace(normalize_whitespace(pg), '-+', E'\u2013') WHERE pg !~ '^([1-9]\d*(\u2013[1-9]\d*)?)?$';
ALTER TABLE citations ADD CHECK (pg ~ '^([1-9]\d*(\u2013[1-9]\d*)?)?$');
ALTER TABLE citations ADD CHECK (is_url_or_empty(url));
ALTER TABLE citations ADD CHECK (is_url_or_empty(pdf));
ALTER TABLE citations ADD CHECK (doi ~ '^(|10\.\d+(\.\d+)?/.+)$');
*/



/* COVARIATES */

-- decide whether to use >= 1 or >= 2
/* ALTER TABLE covariates ADD CHECK (n >= 2); */

-- can do this even if we don't use it right away:
CREATE DOMAIN statnames AS TEXT CHECK (VALUE IN ('SD', 'SE', 'MSE', '95%CI', 'LSD', 'MSD', '')) NOT NULL;
-- see violations of NOT NULL part:
-- SELECT * FROM covariates WHERE statname IS NULL;
-- clean up NULLs in statname:
-- UPDATE covariates SET statname = '' WHERE statname IS NULL;
/* ALTER TABLE covariates ALTER COLUMN statname SET DATA TYPE statnames; */
-- see stat-statname consistency violations:
-- SELECT * FROM  covariates WHERE NOT (statname = '' AND stat IS NULL OR statname != '' AND stat IS NOT NULL);
-- possible consistency constraint:
/* ALTER TABLE covariates ADD CHECK (statname = '' AND stat IS NULL OR statname != '' AND stat IS NOT NULL); */
-- other consistency constraints to be decided


/* CULTIVARS */

ALTER TABLE cultivars ADD CHECK (is_whitespace_normalized(name));
-- decide about ecotype constraint
ALTER TABLE cultivars ALTER COLUMN notes SET NOT NULL;


/* DBFILES */

ALTER TABLE dbfiles ADD CHECK (container_type IN ('Model','Posterior','Input'));
ALTER TABLE dbfiles ADD CHECK (md5 ~ '^([\da-z]{32})?$');
-- decide on other constraints


/* ENSEMBLES */

ALTER TABLE ensembles ALTER COLUMN notes SET NOT NULL;
ALTER TABLE ensembles ALTER COLUMN runtype SET NOT NULL;

/* ENTITIES */

ALTER TABLE entities ADD CHECK (is_whitespace_normalized(name));
ALTER TABLE entities ALTER COLUMN notes SET NOT NULL;


/* FORMATS */

ALTER TABLE formats ALTER COLUMN notes SET NOT NULL;
ALTER TABLE formats ALTER COLUMN name SET NOT NULL;
ALTER TABLE formats ADD CHECK (is_whitespace_normalized(name));
-- decide on constraints for dataformat, header, and skip

/* FORMATS_VARIABLES */

-- decide on constraints

/* INPUTS */






  end

  def self.down
  end
end
