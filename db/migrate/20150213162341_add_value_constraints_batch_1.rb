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
ALTER TABLE citations ADD CHECK (url ~ '^(|(ht|f)tp(s?)\:\/\/(([a-zA-Z0-9\-\._]+(\.[a-zA-Z0-9\-\._]+)+)|localhost)'
                                       '(\/?)([a-zA-Z0-9\-\.\?\,\'\/\\\+&amp;%\$#_]*)?'
                                       '([\d\w\.\/\%\+\-\=\&amp;\?\:\\\&quot;\'\,\|\~\;]*))$');
ALTER TABLE citations ADD CHECK (pdf ~ '^(|(ht|f)tp(s?)\:\/\/(([a-zA-Z0-9\-\._]+(\.[a-zA-Z0-9\-\._]+)+)|localhost)'
                                       '(\/?)([a-zA-Z0-9\-\.\?\,\'\/\\\+&amp;%\$#_]*)?'
                                       '([\d\w\.\/\%\+\-\=\&amp;\?\:\\\&quot;\'\,\|\~\;]*))$');
ALTER TABLE citations ADD CHECK (doi ~ '^(|10\.\d+(\.\d+)?/.+)$');
*/



  end

  def self.down
  end
end
