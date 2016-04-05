--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public, pg_catalog;

--
-- Name: level_of_access; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN level_of_access AS integer NOT NULL
	CONSTRAINT level_of_access_check CHECK (((VALUE >= 1) AND (VALUE <= 4)));


--
-- Name: statnames; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN statnames AS text NOT NULL DEFAULT ''::text
	CONSTRAINT statnames_check CHECK ((VALUE = ANY (ARRAY['SD'::text, 'SE'::text, 'MSE'::text, '95%CI'::text, 'LSD'::text, 'MSD'::text, 'HSD'::text, ''::text])));


--
-- Name: check_for_references(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION check_for_references() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE references_exist boolean;
BEGIN
    SELECT EXISTS(SELECT 1 FROM dbfiles WHERE container_type = TG_ARGV[0]) INTO references_exist;
    IF
        references_exist
    THEN
        RAISE EXCEPTION 'Table % can''t be truncated because rows in the dbfiles table refer to it.', LOWER(TG_ARGV[0]) || 's';
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: forbid_dangling_input_references(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION forbid_dangling_input_references() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF
        OLD.id = SOME(SELECT container_id FROM dbfiles WHERE container_type = 'Input')
        AND (TG_OP IN ('DELETE', 'TRUNCATE') OR NEW.id != OLD.id)
    THEN
        RAISE NOTICE 'You can''t remove or change the id of the row with id % because it is referred to by some dbfile.', OLD.id;
        RETURN NULL;
    END IF;

    IF
        TG_OP = 'DELETE'
    THEN
        RETURN OLD;
    END IF;
    
    RETURN NEW; -- for UPDATEs
END;
$$;


--
-- Name: forbid_dangling_model_references(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION forbid_dangling_model_references() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF
        OLD.id = SOME(SELECT container_id FROM dbfiles WHERE container_type = 'Model')
        AND (TG_OP IN ('DELETE', 'TRUNCATE') OR NEW.id != OLD.id)
    THEN
        RAISE NOTICE 'You can''t remove or change the id of the row with id % because it is referred to by some dbfile.', OLD.id;
        RETURN NULL;
    END IF;

    IF
        TG_OP = 'DELETE'
    THEN
        RETURN OLD;
    END IF;
    
    RETURN NEW; -- for UPDATEs
END;
$$;


--
-- Name: forbid_dangling_posterior_references(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION forbid_dangling_posterior_references() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF
        OLD.id = SOME(SELECT container_id FROM dbfiles WHERE container_type = 'Posterior')
        AND (TG_OP IN ('DELETE', 'TRUNCATE') OR NEW.id != OLD.id)
    THEN
        RAISE NOTICE 'You can''t remove or change the id of the row with id % because it is referred to by some dbfile.', OLD.id;
        RETURN NULL;
    END IF;

    IF
        TG_OP = 'DELETE'
    THEN
        RETURN OLD;
    END IF;
    
    RETURN NEW; -- for UPDATEs
END;
$$;


--
-- Name: get_input_ids(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_input_ids() RETURNS bigint[]
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: get_model_ids(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_model_ids() RETURNS bigint[]
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: get_posterior_ids(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_posterior_ids() RETURNS bigint[]
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: is_host_address(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_host_address(string text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
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
$_$;


--
-- Name: is_numerical(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_numerical(text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE x FLOAT;
BEGIN
   /* We attempt to cast to FLOAT rather than NUMERIC because we want 'INFINITY'
      and '-INFINITY' to count as being numerical. */
    x = $1::FLOAT;
    RETURN TRUE;
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$_$;


--
-- Name: is_url_or_empty(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_url_or_empty(string text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
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
$_$;


--
-- Name: is_wellformed_email(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_wellformed_email(string text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
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
$_$;


--
-- Name: is_whitespace_free(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_whitespace_free(string text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN string !~ '[\s\u00a0]';
END;
$$;


--
-- Name: is_whitespace_normalized(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION is_whitespace_normalized(string text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN string = normalize_whitespace(string);
END;
$$;


--
-- Name: FUNCTION is_whitespace_normalized(string text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION is_whitespace_normalized(string text) IS 'Returns true if text contains no leading or trailing spaces, no whitespace other than spaces, and no consecutive spaces.';


--
-- Name: no_cultivar_member(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION no_cultivar_member(this_pft_id bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  DECLARE cultivar_member_exists boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM cultivars_pfts WHERE pft_id = this_pft_id) INTO cultivar_member_exists;
  RETURN NOT cultivar_member_exists;
END
$$;


--
-- Name: FUNCTION no_cultivar_member(this_pft_id bigint); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION no_cultivar_member(this_pft_id bigint) IS 'Returns TRUE if the pft with id "this_pft_id" contains no members which are cultivars (as opposed to species).';


--
-- Name: no_species_member(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION no_species_member(this_pft_id bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  DECLARE species_member_exists boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM pfts_species WHERE pft_id = this_pft_id) INTO species_member_exists;
  RETURN NOT species_member_exists;
END
$$;


--
-- Name: FUNCTION no_species_member(this_pft_id bigint); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION no_species_member(this_pft_id bigint) IS 'Returns TRUE if the pft with id "this_pft_id" contains no members which are species (as opposed to cultivars).';


--
-- Name: normalize_name_whitespace(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION normalize_name_whitespace() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.name = normalize_whitespace(NEW.name);
  RETURN NEW;
END;
$$;


--
-- Name: normalize_whitespace(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION normalize_whitespace(string text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  result text;
BEGIN
  SELECT TRIM(REGEXP_REPLACE(string, '\s+', ' ', 'g')) INTO result;
  RETURN result;
END;
$$;


--
-- Name: FUNCTION normalize_whitespace(string text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION normalize_whitespace(string text) IS 'Removes leading and trailing whitespace from string and replaces internal sequences of whitespace with a single space character.';


--
-- Name: prevent_conflicting_range_changes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION prevent_conflicting_range_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE name varchar;
    DECLARE min float;
    DECLARE max float;
BEGIN
    SELECT
        min(mean), max(mean) INTO min, max
    FROM
        traits
    WHERE
        NEW.id = traits.variable_id;

    IF
        NEW.min::float > min::float
    THEN
        IF
            NEW.max::float < max
        THEN
            RAISE EXCEPTION 'There are traits for variable % having values that are greater than % and traits having values that are less than %.', OLD.name, NEW.max, NEW.min;
        ELSE
            RAISE EXCEPTION 'There are traits for variable % having values that are less than %.', OLD.name, NEW.min;
        END IF;
    ELSE
        IF
            NEW.max::float < max
        THEN
            RAISE EXCEPTION 'There are traits for variable % having values that are greater than % .', OLD.name, NEW.max;
        END IF;
    END IF;


    SELECT
        min(level), max(level) INTO min, max
    FROM
        covariates
    WHERE
        NEW.id = covariates.variable_id;

    IF
        NEW.min::float > min::float
    THEN
        IF
            NEW.max::float < max
        THEN
            RAISE EXCEPTION 'There are covariates for variable % having values that are greater than % and covariates having values that are less than %.', OLD.name, NEW.max, NEW.min;
        ELSE
            RAISE EXCEPTION 'There are covariates for variable % having values that are less than %.', OLD.name, NEW.min;
        END IF;
    ELSE
        IF
            NEW.max::float < max
        THEN
            RAISE EXCEPTION 'There are covariates for variable % having values that are greater than % .', OLD.name, NEW.max;
        END IF;
    END IF;

    RETURN NEW ;
END;
$$;


--
-- Name: replace_x(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION replace_x() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
BEGIN
    NEW.species = REPLACE(NEW.species, ' x ', E' \u00d7 ');
    NEW.scientificname = REPLACE(NEW.scientificname, ' x ', E' \u00d7 ');
    RETURN NEW; 
END; 
$$;


--
-- Name: restrict_covariate_range(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION restrict_covariate_range() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE name varchar;
    DECLARE min float;
    DECLARE max float;
BEGIN
    SELECT


        -- If min and max are constrained to be non-null, then the
        -- COALESCE call is not needed.  In this case, some very large
        -- number would be used for unconstrained maximimum values and
        -- some large negative number would be used for unconstrained
        -- minimum values.  Alternatively, the type could be changed
        -- to float so that values '-infinity' and 'infinity' could be
        -- used.  In any case, the min and max columns should probably
        -- at least be altered to some numeric type.

        -- If min, max and level are all altered to be of the same
        -- type, then the casts will not be needed.
        
        -- Treat NULLs as if they were infinity.        
        variables.name, CAST(COALESCE(variables.min, '-infinity') AS float), CAST(COALESCE(variables.max, 'infinity') AS float) INTO name, min, max
    FROM
        variables
    WHERE
        variables.id = NEW.variable_id;
    IF
        NEW.level::float < min OR NEW.level::float > max
    THEN
        RAISE EXCEPTION 'The value of level for covariate % must be between % and %.', name, min::text, max::text;
    END IF;
    RETURN NEW ;
END;
$$;


--
-- Name: restrict_trait_range(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION restrict_trait_range() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE name varchar;
    DECLARE min float;
    DECLARE max float;
BEGIN
    SELECT


        -- If min and max are constrained to be non-null, then the
        -- COALESCE call is not needed.  In this case, some very large
        -- number would be used for unconstrained maximimum values and
        -- some large negative number would be used for unconstrained
        -- minimum values.  Alternatively, the type could be changed
        -- to float so that values '-infinity' and 'infinity' could be
        -- used.  In any case, the min and max columns should probably
        -- at least be altered to some numeric type.

        -- If min, max and mean are all altered to be of the same
        -- type, then the casts will not be needed.
        
        -- Treat NULLs as if they were infinity.        
        variables.name, CAST(COALESCE(variables.min, '-infinity') AS float), CAST(COALESCE(variables.max, 'infinity') AS float) INTO name, min, max
    FROM
        variables
    WHERE
        variables.id = NEW.variable_id;
    IF
        NEW.mean::float < min OR NEW.mean::float > max
    THEN
        RAISE EXCEPTION 'The value of mean for trait % must be between % and %.', name, min::text, max::text;
    END IF;
    RETURN NEW ;
END;
$$;


--
-- Name: update_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF
        NEW.updated_at = OLD.updated_at
    THEN
        NEW.updated_at = utc_now();
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: utc_now(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION utc_now() RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN CURRENT_TIMESTAMP AT TIME ZONE 'UTC';
END;
$$;


--
-- Name: citations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE citations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: citations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE citations (
    id bigint DEFAULT nextval('citations_id_seq'::regclass) NOT NULL,
    author character varying(255) NOT NULL,
    year integer NOT NULL,
    title character varying(255) NOT NULL,
    journal character varying(255) DEFAULT ''::character varying NOT NULL,
    vol integer,
    pg character varying(255) DEFAULT ''::character varying NOT NULL,
    url character varying(512) DEFAULT ''::character varying NOT NULL,
    pdf character varying(255) DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    doi character varying(255) DEFAULT ''::character varying NOT NULL,
    user_id bigint,
    CONSTRAINT citation_year_not_in_future CHECK (((year)::double precision <= (date_part('year'::text, now()) + (1)::double precision))),
    CONSTRAINT non_negative_citation_volume_number CHECK ((vol >= 0)),
    CONSTRAINT normalized_citation_authors CHECK (is_whitespace_normalized((author)::text)),
    CONSTRAINT normalized_citation_journals CHECK (is_whitespace_normalized((journal)::text)),
    CONSTRAINT normalized_citation_titles CHECK (is_whitespace_normalized((title)::text)),
    CONSTRAINT well_formed_citation_doi CHECK (((doi)::text ~ '^(|10\.\d+(\.\d+)?/.+)$'::text)),
    CONSTRAINT well_formed_citation_page_spec CHECK (((pg)::text ~ '^([1-9]\d*(\u2013[1-9]\d*)?)?$'::text)),
    CONSTRAINT well_formed_citation_pdf_url CHECK ((is_url_or_empty((pdf)::text) OR ((pdf)::text ~ '^\(.+\)$'::text))),
    CONSTRAINT well_formed_citation_url CHECK ((is_url_or_empty((url)::text) OR ((url)::text ~ '^\(.+\)$'::text)))
);


--
-- Name: COLUMN citations.author; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN citations.author IS 'last name of first author';


--
-- Name: COLUMN citations.year; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN citations.year IS 'year of publication';


--
-- Name: COLUMN citations.title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN citations.title IS 'article title';


--
-- Name: COLUMN citations.journal; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN citations.journal IS 'Journal name';


--
-- Name: COLUMN citations.pg; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN citations.pg IS 'page range of article';


--
-- Name: COLUMN citations.url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN citations.url IS 'link to article url';


--
-- Name: COLUMN citations.pdf; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN citations.pdf IS 'link to pdf version of article';


--
-- Name: COLUMN citations.doi; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN citations.doi IS 'Digital Object Identifier';


--
-- Name: citations_sites; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE citations_sites (
    citation_id bigint NOT NULL,
    site_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    id bigint NOT NULL
);


--
-- Name: citations_sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE citations_sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: citations_sites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE citations_sites_id_seq OWNED BY citations_sites.id;


--
-- Name: citations_treatments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE citations_treatments (
    citation_id bigint NOT NULL,
    treatment_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    id bigint NOT NULL
);


--
-- Name: citations_treatments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE citations_treatments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: citations_treatments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE citations_treatments_id_seq OWNED BY citations_treatments.id;


--
-- Name: counties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE counties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: covariates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE covariates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: covariates; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE covariates (
    id bigint DEFAULT nextval('covariates_id_seq'::regclass) NOT NULL,
    trait_id bigint,
    variable_id bigint,
    level double precision,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    n integer,
    statname statnames DEFAULT ''::text,
    stat double precision,
    CONSTRAINT positive_covariate_sample_size CHECK ((n >= 1))
);


--
-- Name: COLUMN covariates.level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN covariates.level IS 'Value of covariate, units are determined in variables table by the variable_id foreign key.';


--
-- Name: cultivars_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cultivars_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cultivars; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cultivars (
    id bigint DEFAULT nextval('cultivars_id_seq'::regclass) NOT NULL,
    specie_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    ecotype character varying(255) DEFAULT ''::character varying NOT NULL,
    notes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    previous_id character varying(255),
    CONSTRAINT normalized_names CHECK (is_whitespace_normalized((name)::text))
);


--
-- Name: COLUMN cultivars.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN cultivars.name IS 'Cultivar name given by breeder or reported in citation.';


--
-- Name: COLUMN cultivars.ecotype; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN cultivars.ecotype IS 'An ecotype is a distinct variety adapted to a particular environment. Implemented to distinguish ''upland'' and ''lowland'' Switchgrass cultivars.  Can also be used to distinguish, e.g. species in temperate vs. tundra';


--
-- Name: cultivars_pfts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cultivars_pfts (
    pft_id bigint NOT NULL,
    cultivar_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT utc_now(),
    updated_at timestamp without time zone DEFAULT utc_now(),
    CONSTRAINT no_conflicting_member CHECK (no_species_member(pft_id))
);


--
-- Name: TABLE cultivars_pfts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE cultivars_pfts IS 'This table tells which cultivars are members of which pfts.  For each row, the cultivar with id "cultivar_id" is a member of the pft with id "pft_id".';


--
-- Name: CONSTRAINT no_conflicting_member ON cultivars_pfts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT no_conflicting_member ON cultivars_pfts IS 'Ensure the pft_id does not refer to a pft having one or more species as members; pfts referred to by this table can only contain other cultivars.';


--
-- Name: current_posteriors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE current_posteriors (
    id bigint NOT NULL,
    pft_id bigint,
    variable_id bigint,
    posteriors_samples_id bigint,
    project_id bigint,
    created_at timestamp without time zone DEFAULT utc_now(),
    updated_at timestamp without time zone DEFAULT utc_now()
);


--
-- Name: COLUMN current_posteriors.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN current_posteriors.id IS 'This table makes it easier to identify the ''latest'' posterior for any PFT or other functional grouping. For example, if you query a specific PFT and project you get the list of variables that have been estimated and their (joint) posteriors.';


--
-- Name: current_posteriors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE current_posteriors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: current_posteriors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE current_posteriors_id_seq OWNED BY current_posteriors.id;


--
-- Name: dbfiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE dbfiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dbfiles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE dbfiles (
    id bigint DEFAULT nextval('dbfiles_id_seq'::regclass) NOT NULL,
    file_name character varying(255) NOT NULL,
    file_path character varying(255) NOT NULL,
    md5 character varying(255),
    created_user_id bigint,
    updated_user_id bigint,
    machine_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    container_type character varying(255),
    container_id bigint,
    CONSTRAINT file_path_sanity_check CHECK (((file_path)::text ~ '^/'::text)),
    CONSTRAINT no_slash_in_file_name CHECK (((file_name)::text !~ '/'::text)),
    CONSTRAINT valid_dbfile_container_type CHECK (((container_type)::text = ANY ((ARRAY['Model'::character varying, 'Posterior'::character varying, 'Input'::character varying])::text[]))),
    CONSTRAINT valid_dbfile_md5_hash_value CHECK (((md5)::text ~ '^([\da-z]{32})?$'::text)),
    CONSTRAINT valid_input_refs CHECK ((((container_type)::text <> 'Input'::text) OR (container_id = ANY (get_input_ids())))),
    CONSTRAINT valid_model_refs CHECK ((((container_type)::text <> 'Model'::text) OR (container_id = ANY (get_model_ids())))),
    CONSTRAINT valid_posterior_refs CHECK ((((container_type)::text <> 'Posterior'::text) OR (container_id = ANY (get_posterior_ids()))))
);


--
-- Name: COLUMN dbfiles.container_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN dbfiles.container_type IS 'this and container_id are part of a polymorphic relationship, specifies table and primary key of that table';


--
-- Name: ensembles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ensembles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ensembles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ensembles (
    id bigint DEFAULT nextval('ensembles_id_seq'::regclass) NOT NULL,
    notes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    runtype character varying(255) NOT NULL,
    workflow_id bigint
);


--
-- Name: entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: entities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE entities (
    id bigint DEFAULT nextval('entities_id_seq'::regclass) NOT NULL,
    parent_id bigint,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    notes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    CONSTRAINT normalized_entity_name CHECK (is_whitespace_normalized((name)::text))
);


--
-- Name: formats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE formats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: formats; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE formats (
    id bigint DEFAULT nextval('formats_id_seq'::regclass) NOT NULL,
    notes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    name character varying(255) NOT NULL,
    header character varying(255) DEFAULT ''::character varying NOT NULL,
    skip character varying(255) DEFAULT ''::character varying NOT NULL,
    mimetype_id bigint,
    CONSTRAINT normalized_format_name CHECK (is_whitespace_normalized((name)::text))
);


--
-- Name: formats_variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE formats_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: formats_variables; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE formats_variables (
    id bigint DEFAULT nextval('formats_variables_id_seq'::regclass) NOT NULL,
    format_id bigint NOT NULL,
    variable_id bigint NOT NULL,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    unit character varying(255) DEFAULT ''::character varying NOT NULL,
    storage_type character varying(255) DEFAULT ''::character varying NOT NULL,
    column_number integer,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now()
);


--
-- Name: inputs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE inputs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inputs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE inputs (
    id bigint DEFAULT nextval('inputs_id_seq'::regclass) NOT NULL,
    site_id bigint,
    notes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    start_date timestamp(6) without time zone,
    end_date timestamp(6) without time zone,
    name character varying(255) NOT NULL,
    parent_id bigint,
    user_id bigint,
    access_level level_of_access DEFAULT 4,
    raw boolean,
    format_id bigint,
    CONSTRAINT normalized_input_name CHECK (is_whitespace_normalized((name)::text))
);


--
-- Name: inputs_runs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE inputs_runs (
    input_id bigint NOT NULL,
    run_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    id bigint NOT NULL
);


--
-- Name: inputs_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE inputs_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inputs_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE inputs_runs_id_seq OWNED BY inputs_runs.id;


--
-- Name: likelihoods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE likelihoods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: likelihoods; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE likelihoods (
    id bigint DEFAULT nextval('likelihoods_id_seq'::regclass) NOT NULL,
    run_id bigint NOT NULL,
    variable_id bigint NOT NULL,
    input_id bigint NOT NULL,
    loglikelihood numeric(10,0),
    n_eff numeric(10,0),
    weight numeric(10,0),
    residual numeric(10,0),
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now()
);


--
-- Name: location_yields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE location_yields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE machines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: machines; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE machines (
    id bigint DEFAULT nextval('machines_id_seq'::regclass) NOT NULL,
    hostname character varying(255) NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    sync_host_id bigint,
    sync_url character varying(255),
    sync_contact character varying(255),
    sync_start bigint,
    sync_end bigint,
    CONSTRAINT well_formed_machine_hostname CHECK (is_host_address((hostname)::text))
);


--
-- Name: managements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE managements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: managements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE managements (
    id bigint DEFAULT nextval('managements_id_seq'::regclass) NOT NULL,
    citation_id bigint,
    date date,
    dateloc numeric(4,2),
    mgmttype character varying(255) NOT NULL,
    level double precision,
    units character varying(255),
    notes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    user_id bigint
);


--
-- Name: COLUMN managements.date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN managements.date IS 'Date on which management was conducted.';


--
-- Name: COLUMN managements.dateloc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN managements.dateloc IS 'Level of confidence in value given as date. See documentation for details.';


--
-- Name: COLUMN managements.mgmttype; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN managements.mgmttype IS 'Type of management';


--
-- Name: COLUMN managements.level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN managements.level IS 'Amount applied, not always required.';


--
-- Name: COLUMN managements.units; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN managements.units IS 'units, standardized for each management type.';


--
-- Name: managements_treatments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE managements_treatments (
    treatment_id bigint NOT NULL,
    management_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    id bigint NOT NULL
);


--
-- Name: managements_treatments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE managements_treatments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: managements_treatments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE managements_treatments_id_seq OWNED BY managements_treatments.id;


--
-- Name: methods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: methods; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE methods (
    id bigint DEFAULT nextval('methods_id_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    description text NOT NULL,
    citation_id bigint,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    CONSTRAINT normalized_method_name CHECK (is_whitespace_normalized((name)::text))
);


--
-- Name: mimetypes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mimetypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mimetypes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mimetypes (
    id bigint DEFAULT nextval('mimetypes_id_seq'::regclass) NOT NULL,
    type_string character varying(255) NOT NULL,
    CONSTRAINT valid_mime_type CHECK (((type_string)::text ~ '^(application|audio|chemical|drawing|image|i-world|message|model|multipart|music|paleovu|text|video|windows|www|x-conference|xgl|x-music|x-world)/[a-z.0-9_-]+( \((old|compiled elisp)\))?$'::text))
);


--
-- Name: models_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE models_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: models; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE models (
    id bigint DEFAULT nextval('models_id_seq'::regclass) NOT NULL,
    model_name character varying(255) NOT NULL,
    revision character varying(255) NOT NULL,
    parent_id bigint,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    modeltype_id bigint NOT NULL,
    CONSTRAINT no_spaces_in_model_name CHECK (is_whitespace_free((model_name)::text)),
    CONSTRAINT normalized_revision_specifier CHECK (is_whitespace_normalized((revision)::text))
);


--
-- Name: modeltypes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE modeltypes (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    user_id bigint,
    created_at timestamp without time zone DEFAULT utc_now(),
    updated_at timestamp without time zone DEFAULT utc_now(),
    CONSTRAINT no_spaces_in_modeltype_name CHECK (is_whitespace_free((name)::text))
);


--
-- Name: modeltypes_formats; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE modeltypes_formats (
    id bigint NOT NULL,
    modeltype_id bigint NOT NULL,
    tag character varying(255) NOT NULL,
    format_id bigint NOT NULL,
    required boolean DEFAULT false NOT NULL,
    input boolean DEFAULT true NOT NULL,
    user_id bigint,
    created_at timestamp without time zone DEFAULT utc_now(),
    updated_at timestamp without time zone DEFAULT utc_now(),
    CONSTRAINT valid_modeltype_format_tag CHECK (((tag)::text ~ '^[a-z]+$'::text))
);


--
-- Name: modeltypes_formats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE modeltypes_formats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: modeltypes_formats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE modeltypes_formats_id_seq OWNED BY modeltypes_formats.id;


--
-- Name: modeltypes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE modeltypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: modeltypes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE modeltypes_id_seq OWNED BY modeltypes.id;


--
-- Name: pfts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pfts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pfts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pfts (
    id bigint DEFAULT nextval('pfts_id_seq'::regclass) NOT NULL,
    definition text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    name character varying(255) NOT NULL,
    parent_id bigint,
    pft_type character varying(255) DEFAULT 'plant'::character varying NOT NULL,
    modeltype_id bigint NOT NULL,
    CONSTRAINT normalized_pft_name CHECK (is_whitespace_normalized((name)::text)),
    CONSTRAINT valid_pft_type CHECK (((pft_type)::text = ANY ((ARRAY['plant'::character varying, 'cultivar'::character varying, ''::character varying])::text[])))
);


--
-- Name: COLUMN pfts.definition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pfts.definition IS 'Defines the creator and context under which the pft will be used.';


--
-- Name: COLUMN pfts.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pfts.name IS 'pft names are unique within a given model type.';


--
-- Name: pfts_priors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pfts_priors (
    pft_id bigint NOT NULL,
    prior_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    id bigint NOT NULL
);


--
-- Name: pfts_priors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pfts_priors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pfts_priors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pfts_priors_id_seq OWNED BY pfts_priors.id;


--
-- Name: pfts_species; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pfts_species (
    pft_id bigint NOT NULL,
    specie_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    id bigint NOT NULL,
    CONSTRAINT no_conflicting_member CHECK (no_cultivar_member(pft_id))
);


--
-- Name: TABLE pfts_species; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE pfts_species IS 'This table tells which species are members of which pfts.  For each row, the species with id "specie_id" is a member of the pft with id "pft_id".';


--
-- Name: CONSTRAINT no_conflicting_member ON pfts_species; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT no_conflicting_member ON pfts_species IS 'Ensure the pft_id does not refer to a pft having one or more cultivars as members; pfts referred to by this table con only contain other species.';


--
-- Name: pfts_species_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pfts_species_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pfts_species_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pfts_species_id_seq OWNED BY pfts_species.id;


--
-- Name: posterior_samples; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE posterior_samples (
    id bigint NOT NULL,
    posterior_id bigint,
    variable_id bigint,
    pft_id bigint,
    parent_id bigint,
    created_at timestamp without time zone DEFAULT utc_now(),
    updated_at timestamp without time zone DEFAULT utc_now()
);


--
-- Name: COLUMN posterior_samples.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN posterior_samples.id IS 'Allows a posterior to be updated asynchronously (i.e. for a given PFT, not all variables have to have the same posterior_id).';


--
-- Name: posterior_samples_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE posterior_samples_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posterior_samples_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE posterior_samples_id_seq OWNED BY posterior_samples.id;


--
-- Name: posteriors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE posteriors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posteriors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE posteriors (
    id bigint DEFAULT nextval('posteriors_id_seq'::regclass) NOT NULL,
    pft_id bigint NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now()
);


--
-- Name: posteriors_ensembles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE posteriors_ensembles (
    posterior_id bigint,
    ensemble_id bigint,
    created_at timestamp without time zone DEFAULT utc_now(),
    updated_at timestamp without time zone DEFAULT utc_now(),
    id bigint NOT NULL
);


--
-- Name: COLUMN posteriors_ensembles.posterior_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN posteriors_ensembles.posterior_id IS 'Allows analyst to more easily see the functional grouping of the different sets of model runs used to generate a posterior.';


--
-- Name: posteriors_ensembles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE posteriors_ensembles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posteriors_ensembles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE posteriors_ensembles_id_seq OWNED BY posteriors_ensembles.id;


--
-- Name: priors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE priors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: priors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE priors (
    id bigint DEFAULT nextval('priors_id_seq'::regclass) NOT NULL,
    citation_id bigint,
    variable_id bigint NOT NULL,
    phylogeny character varying(255) NOT NULL,
    distn character varying(255) NOT NULL,
    parama double precision NOT NULL,
    paramb double precision,
    paramc double precision,
    n integer,
    notes text,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    CONSTRAINT nonnegative_prior_sample_size CHECK ((n >= 0)),
    CONSTRAINT normalized_prior_phylogeny_specifier CHECK (is_whitespace_normalized((phylogeny)::text)),
    CONSTRAINT valid_prior_distn CHECK (((distn)::text = ANY ((ARRAY['beta'::character varying, 'binom'::character varying, 'cauchy'::character varying, 'chisq'::character varying, 'exp'::character varying, 'f'::character varying, 'gamma'::character varying, 'geom'::character varying, 'hyper'::character varying, 'lnorm'::character varying, 'logis'::character varying, 'nbinom'::character varying, 'norm'::character varying, 'pois'::character varying, 't'::character varying, 'unif'::character varying, 'weibull'::character varying, 'wilcox'::character varying])::text[])))
);


--
-- Name: COLUMN priors.phylogeny; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN priors.phylogeny IS 'Used to note the group of plants for which the prior was specified, often the group of plants represented by the data used to specify the prior.';


--
-- Name: COLUMN priors.distn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN priors.distn IS 'Name of the probability distribution, using R naming convention (e.g. ''beta'',''f'', ''gamma'', ''lnorm'', ''norm'', ''pois'', ''t'', ''unif'', ''weibull''.';


--
-- Name: COLUMN priors.parama; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN priors.parama IS 'First parameter for distribution, as specified by R.';


--
-- Name: COLUMN priors.paramb; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN priors.paramb IS 'Second parameter for distribution, as specified by R.';


--
-- Name: COLUMN priors.paramc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN priors.paramc IS 'A third parameter, if required.';


--
-- Name: COLUMN priors.n; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN priors.n IS 'number of observations used to specify prior.';


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE projects (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    outdir character varying(255) NOT NULL,
    machine_id bigint,
    description character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT utc_now(),
    updated_at timestamp without time zone DEFAULT utc_now(),
    CONSTRAINT normalized_project_name CHECK (is_whitespace_normalized((name)::text))
);


--
-- Name: COLUMN projects.id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN projects.id IS 'Defines the directory under which a set of analyses is done. Will allow migration of content from PEcAn settings.xml files that are not specific to a particular workflow instance but rather are shared across a set of analyses out of the settings file and into the database. There might be multiple ''workflows'' or analyses within a single project, but each of their workflows.outdir should be within the larger projects.outdir.';


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE projects_id_seq OWNED BY projects.id;


--
-- Name: runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: runs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE runs (
    id bigint DEFAULT nextval('runs_id_seq'::regclass) NOT NULL,
    model_id bigint NOT NULL,
    site_id bigint NOT NULL,
    start_time timestamp(6) without time zone NOT NULL,
    finish_time timestamp(6) without time zone NOT NULL,
    outdir character varying(255) DEFAULT ''::character varying NOT NULL,
    outprefix character varying(255) DEFAULT ''::character varying NOT NULL,
    setting character varying(255) DEFAULT ''::character varying NOT NULL,
    parameter_list text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    started_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    ensemble_id bigint NOT NULL
);


--
-- Name: COLUMN runs.start_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN runs.start_time IS 'beginning of time period being simulated';


--
-- Name: COLUMN runs.finish_time; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN runs.finish_time IS 'end of time period being simulated';


--
-- Name: COLUMN runs.started_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN runs.started_at IS 'system time when run was started';


--
-- Name: COLUMN runs.finished_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN runs.finished_at IS 'system time when run ends; can be null when record is created';


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sessions (
    id bigint DEFAULT nextval('sessions_id_seq'::regclass) NOT NULL,
    session_id character varying(255) NOT NULL,
    data text,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now()
);


--
-- Name: sites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sites; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE sites (
    id bigint DEFAULT nextval('sites_id_seq'::regclass) NOT NULL,
    city character varying(255) DEFAULT ''::character varying NOT NULL,
    state character varying(255) DEFAULT ''::character varying NOT NULL,
    country character varying(255) DEFAULT ''::character varying NOT NULL,
    mat numeric(4,2),
    map integer,
    soil character varying(255) DEFAULT ''::character varying NOT NULL,
    som numeric(4,2),
    notes text DEFAULT ''::text NOT NULL,
    soilnotes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    sitename character varying(255) NOT NULL,
    greenhouse boolean,
    user_id bigint,
    local_time integer,
    sand_pct numeric(9,5),
    clay_pct numeric(9,5),
    geometry geometry(GeometryZ,4326),
    CONSTRAINT enforce_valid_geom CHECK (st_isvalid(geometry)),
    CONSTRAINT normalized_site_city_name CHECK (is_whitespace_normalized((city)::text)),
    CONSTRAINT normalized_site_country_name CHECK (is_whitespace_normalized((country)::text)),
    CONSTRAINT normalized_site_sitename CHECK (is_whitespace_normalized((sitename)::text)),
    CONSTRAINT normalized_site_state_name CHECK (is_whitespace_normalized((state)::text)),
    CONSTRAINT valid_site_geometry_specification CHECK (((((st_x(st_centroid(geometry)) >= ((-180))::double precision) AND (st_x(st_centroid(geometry)) <= (180)::double precision)) AND ((st_y(st_centroid(geometry)) >= ((-90))::double precision) AND (st_y(st_centroid(geometry)) <= (90)::double precision))) AND ((st_z(st_centroid(geometry)) >= ((-418))::double precision) AND (st_z(st_centroid(geometry)) <= (8848)::double precision)))),
    CONSTRAINT valid_site_map_value CHECK (((map >= 0) AND (map <= 12000))),
    CONSTRAINT valid_site_mat_value CHECK (((mat >= ((-25))::numeric) AND (mat <= (40)::numeric))),
    CONSTRAINT valid_site_sand_and_clay_percentage_values CHECK ((((((sand_pct >= (0)::numeric) AND (clay_pct >= (0)::numeric)) AND (sand_pct <= (100)::numeric)) AND (clay_pct <= (100)::numeric)) AND ((sand_pct + clay_pct) <= (100)::numeric))),
    CONSTRAINT valid_site_som_value CHECK (((som >= (0)::numeric) AND (som <= (100)::numeric)))
);


--
-- Name: COLUMN sites.city; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN sites.city IS 'Nearest city to site.';


--
-- Name: COLUMN sites.state; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN sites.state IS 'If in the United States, state in which study is conducted.';


--
-- Name: COLUMN sites.mat; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN sites.mat IS 'Mean Annual Temperature (C)';


--
-- Name: COLUMN sites.map; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN sites.map IS 'Mean Annual Precipitation (mm)';


--
-- Name: COLUMN sites.soil; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN sites.soil IS 'Soil type, as described in documentation.';


--
-- Name: COLUMN sites.som; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN sites.som IS 'Depreciated';


--
-- Name: COLUMN sites.greenhouse; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN sites.greenhouse IS 'Boolean: indicates if study was conducted in a field (0) or greenhouse, pot, or growth chamber (1)';


--
-- Name: species_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE species_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: species; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE species (
    id bigint DEFAULT nextval('species_id_seq'::regclass) NOT NULL,
    spcd integer,
    genus character varying(255) DEFAULT ''::character varying NOT NULL,
    species character varying(255) DEFAULT ''::character varying NOT NULL,
    scientificname character varying(255) NOT NULL,
    commonname character varying(255) DEFAULT ''::character varying NOT NULL,
    notes character varying(255) DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    "AcceptedSymbol" character varying(255),
    "SynonymSymbol" character varying(255),
    "Symbol" character varying(255),
    "PLANTS_Floristic_Area" text,
    "State" text,
    "Category" character varying(255),
    "Family" character varying(255),
    "FamilySymbol" character varying(255),
    "FamilyCommonName" character varying(255),
    "xOrder" character varying(255),
    "SubClass" character varying(255),
    "Class" character varying(255),
    "SubDivision" character varying(255),
    "Division" character varying(255),
    "SuperDivision" character varying(255),
    "SubKingdom" character varying(255),
    "Kingdom" character varying(255),
    "ITIS_TSN" integer,
    "Duration" character varying(255),
    "GrowthHabit" character varying(255),
    "NativeStatus" character varying(255),
    "NationalWetlandIndicatorStatus" character varying(255),
    "RegionalWetlandIndicatorStatus" character varying(255),
    "ActiveGrowthPeriod" character varying(255),
    "AfterHarvestRegrowthRate" character varying(255),
    "Bloat" character varying(255),
    "C2N_Ratio" character varying(255),
    "CoppicePotential" character varying(255),
    "FallConspicuous" character varying(255),
    "FireResistance" character varying(255),
    "FoliageTexture" character varying(255),
    "GrowthForm" character varying(255),
    "GrowthRate" character varying(255),
    "MaxHeight20Yrs" integer,
    "MatureHeight" integer,
    "KnownAllelopath" character varying(255),
    "LeafRetention" character varying(255),
    "Lifespan" character varying(255),
    "LowGrowingGrass" character varying(255),
    "NitrogenFixation" character varying(255),
    "ResproutAbility" character varying(255),
    "AdaptedCoarseSoils" character varying(255),
    "AdaptedMediumSoils" character varying(255),
    "AdaptedFineSoils" character varying(255),
    "AnaerobicTolerance" character varying(255),
    "CaCO3Tolerance" character varying(255),
    "ColdStratification" character varying(255),
    "DroughtTolerance" character varying(255),
    "FertilityRequirement" character varying(255),
    "FireTolerance" character varying(255),
    "MinFrostFreeDays" integer,
    "HedgeTolerance" character varying(255),
    "MoistureUse" character varying(255),
    "pH_Minimum" numeric(5,2),
    "pH_Maximum" numeric(5,2),
    "Min_PlantingDensity" integer,
    "Max_PlantingDensity" integer,
    "Precipitation_Minimum" integer,
    "Precipitation_Maximum" integer,
    "RootDepthMinimum" integer,
    "SalinityTolerance" character varying(255),
    "ShadeTolerance" character varying(255),
    "TemperatureMinimum" integer,
    "BloomPeriod" character varying(255),
    "CommercialAvailability" character varying(255),
    "FruitSeedPeriodBegin" character varying(255),
    "FruitSeedPeriodEnd" character varying(255),
    "Propogated_by_BareRoot" character varying(255),
    "Propogated_by_Bulbs" character varying(255),
    "Propogated_by_Container" character varying(255),
    "Propogated_by_Corms" character varying(255),
    "Propogated_by_Cuttings" character varying(255),
    "Propogated_by_Seed" character varying(255),
    "Propogated_by_Sod" character varying(255),
    "Propogated_by_Sprigs" character varying(255),
    "Propogated_by_Tubers" character varying(255),
    "Seeds_per_Pound" integer,
    "SeedSpreadRate" character varying(255),
    "SeedlingVigor" character varying(255),
    CONSTRAINT normalized_species_commonname CHECK (is_whitespace_normalized((commonname)::text)),
    CONSTRAINT normalized_species_scientificname CHECK (is_whitespace_normalized((scientificname)::text)),
    CONSTRAINT valid_genus_name CHECK (((genus)::text ~ '^([A-Z][-a-z]*)?$'::text)),
    CONSTRAINT valid_species_designation CHECK (((species)::text ~ '^(([A-Z]\.|[a-zA-Z]{2,}\.?|&|\u00d7)( |-|$))*$'::text)),
    CONSTRAINT valid_species_spcd_value CHECK (((spcd >= 0) AND (spcd <= 10000)))
);


--
-- Name: trait_covariate_associations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE trait_covariate_associations (
    trait_variable_id bigint NOT NULL,
    covariate_variable_id bigint NOT NULL,
    required boolean NOT NULL
);


--
-- Name: traits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE traits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: traits; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE traits (
    id bigint DEFAULT nextval('traits_id_seq'::regclass) NOT NULL,
    site_id bigint,
    specie_id bigint,
    citation_id bigint,
    cultivar_id bigint,
    treatment_id bigint,
    date timestamp(6) without time zone,
    dateloc numeric(4,2),
    "time" time(6) without time zone,
    timeloc numeric(4,2),
    mean double precision,
    n integer,
    statname statnames DEFAULT ''::text,
    stat double precision,
    notes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    variable_id bigint,
    user_id bigint,
    checked integer DEFAULT 0,
    access_level integer,
    entity_id bigint,
    method_id bigint,
    date_year integer,
    date_month integer,
    date_day integer,
    time_hour integer,
    time_minute integer,
    CONSTRAINT valid_trait_checked_value CHECK (((checked >= (-1)) AND (checked <= 1)))
);


--
-- Name: COLUMN traits.site_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.site_id IS 'Site at which measurement was taken.';


--
-- Name: COLUMN traits.specie_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.specie_id IS 'Species on which measurement was taken.';


--
-- Name: COLUMN traits.citation_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.citation_id IS 'Citation in which data was originally reported.';


--
-- Name: COLUMN traits.cultivar_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.cultivar_id IS 'Cultivar information, if any.';


--
-- Name: COLUMN traits.treatment_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.treatment_id IS 'Experimental treatment identification. Required, can indicate observational study.';


--
-- Name: COLUMN traits.date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.date IS 'Date on which measurement was made.';


--
-- Name: COLUMN traits.dateloc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.dateloc IS 'Level of confidence in date. See documentation.';


--
-- Name: COLUMN traits."time"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits."time" IS 'Time at which measurement was taken. Sometimes necessary, e.g. for photosynthesis measurements.';


--
-- Name: COLUMN traits.timeloc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.timeloc IS 'Level of confidence in time.';


--
-- Name: COLUMN traits.mean; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.mean IS 'Mean value of trait.';


--
-- Name: COLUMN traits.n; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.n IS 'Number of experimental replicates used to estimate mean and statistical summary.';


--
-- Name: COLUMN traits.statname; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.statname IS 'Name of reported statistic.';


--
-- Name: COLUMN traits.stat; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.stat IS 'Value of reported statistic.';


--
-- Name: COLUMN traits.variable_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.variable_id IS 'Links to information in variables table that describes trait being measured. ';


--
-- Name: COLUMN traits.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.user_id IS 'ID of user who entered data.';


--
-- Name: COLUMN traits.checked; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.checked IS 'accepts values [-1, 0, 1]. 0 is default, and means that data have not been checked. 1 indicates that the data have been checked and are correct, -1 indicates that data have been checked and found to be incorrect or suspicious, e.g. outside of the acceptab';


--
-- Name: COLUMN traits.access_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN traits.access_level IS 'Level of access required to view data.';


--
-- Name: treatments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE treatments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: treatments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE treatments (
    id bigint DEFAULT nextval('treatments_id_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    definition character varying(255) DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    control boolean,
    user_id bigint,
    CONSTRAINT normalized_treatment_definition CHECK (is_whitespace_normalized((definition)::text)),
    CONSTRAINT normalized_treatment_name CHECK (is_whitespace_normalized((name)::text))
);


--
-- Name: COLUMN treatments.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN treatments.name IS 'Name of treatment, should be easy to associate with treatment name in original study.';


--
-- Name: COLUMN treatments.definition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN treatments.definition IS 'Description of treatment, e.g. levels of fertilizer applied, etc. This information may be redundant with ''levels'' information recorded in Managements table.';


--
-- Name: COLUMN treatments.control; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN treatments.control IS 'Boolean, indicates if treatment is a control or observational (1) or experimental treatment (0).';


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id bigint DEFAULT nextval('users_id_seq'::regclass) NOT NULL,
    login character varying(40) NOT NULL,
    name character varying(100) DEFAULT ''::character varying NOT NULL,
    email character varying(100) NOT NULL,
    city character varying(255) DEFAULT ''::character varying NOT NULL,
    country character varying(255) DEFAULT ''::character varying NOT NULL,
    area character varying(255),
    crypted_password character varying(40) NOT NULL,
    salt character varying(40),
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    remember_token character varying(40),
    remember_token_expires_at timestamp(6) without time zone,
    access_level level_of_access,
    page_access_level level_of_access,
    apikey character varying(255),
    state_prov character varying(255) DEFAULT ''::character varying NOT NULL,
    postal_code character varying(255) DEFAULT ''::character varying NOT NULL,
    CONSTRAINT normalized_postal_code CHECK (is_whitespace_normalized((postal_code)::text)),
    CONSTRAINT normalized_stat_prov_name CHECK (is_whitespace_normalized((state_prov)::text)),
    CONSTRAINT normalized_user_city_name CHECK (is_whitespace_normalized((city)::text)),
    CONSTRAINT normalized_user_country_name CHECK (is_whitespace_normalized((country)::text)),
    CONSTRAINT normalized_user_name CHECK (is_whitespace_normalized((name)::text)),
    CONSTRAINT valid_user_apikey_value CHECK (((apikey)::text ~ '^[0-9a-zA-Z+/]{40}$'::text)),
    CONSTRAINT valid_user_crypted_password_value CHECK (((crypted_password)::text ~ '^[0-9a-f]{1,40}$'::text)),
    CONSTRAINT valid_user_login CHECK (((login)::text ~ '^[a-z\d_][a-z\d_.@-]{2,39}$'::text)),
    CONSTRAINT well_formed_user_email CHECK (is_wellformed_email((email)::text))
);


--
-- Name: COLUMN users.login; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN users.login IS 'login id';


--
-- Name: COLUMN users.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN users.name IS 'User name';


--
-- Name: COLUMN users.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN users.email IS 'email address';


--
-- Name: COLUMN users.access_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN users.access_level IS 'data to which user has access';


--
-- Name: COLUMN users.page_access_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN users.page_access_level IS 'Determines the extent of data, if any, that user can edit.';


--
-- Name: variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: variables; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE variables (
    id bigint DEFAULT nextval('variables_id_seq'::regclass) NOT NULL,
    description character varying(255) DEFAULT ''::character varying NOT NULL,
    units character varying(255) DEFAULT ''::character varying NOT NULL,
    notes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    name character varying(255) NOT NULL,
    max character varying(255) DEFAULT 'Infinity'::character varying NOT NULL,
    min character varying(255) DEFAULT '-Infinity'::character varying NOT NULL,
    standard_name character varying(255),
    standard_units character varying(255),
    label character varying(255),
    type character varying(255),
    CONSTRAINT normalized_variable_description CHECK (is_whitespace_normalized((description)::text)),
    CONSTRAINT normalized_variable_name CHECK (is_whitespace_normalized((name)::text)),
    CONSTRAINT normalized_variable_units_specifier CHECK (is_whitespace_normalized((units)::text)),
    CONSTRAINT variable_max_is_a_number CHECK (is_numerical((max)::text)),
    CONSTRAINT variable_min_is_a_number CHECK (is_numerical((min)::text)),
    CONSTRAINT variable_min_is_less_than_max CHECK (((min)::double precision <= (max)::double precision))
);


--
-- Name: COLUMN variables.description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN variables.description IS 'Description or definition of variable.';


--
-- Name: COLUMN variables.units; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN variables.units IS 'units in which data must be entered.';


--
-- Name: COLUMN variables.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN variables.name IS 'variable name, this is the name used by PEcAn and in other modeling contexts.';


--
-- Name: traitsview_private; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW traitsview_private AS
 SELECT 'traits'::character(10) AS result_type,
    traits.id,
    traits.citation_id,
    traits.site_id,
    traits.treatment_id,
    sites.sitename,
    sites.city,
    st_y(st_centroid(sites.geometry)) AS lat,
    st_x(st_centroid(sites.geometry)) AS lon,
    species.scientificname,
    species.commonname,
    species.genus,
    species.id AS species_id,
    traits.cultivar_id,
    citations.author,
    citations.year AS citation_year,
    treatments.name AS treatment,
    traits.date,
    date_part('month'::text, traits.date) AS month,
    date_part('year'::text, traits.date) AS year,
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
   FROM ((((((traits
     LEFT JOIN sites ON ((traits.site_id = sites.id)))
     LEFT JOIN species ON ((traits.specie_id = species.id)))
     LEFT JOIN citations ON ((traits.citation_id = citations.id)))
     LEFT JOIN treatments ON ((traits.treatment_id = treatments.id)))
     LEFT JOIN variables ON ((traits.variable_id = variables.id)))
     LEFT JOIN users ON ((traits.user_id = users.id)));


--
-- Name: yields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE yields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: yields; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE yields (
    id bigint DEFAULT nextval('yields_id_seq'::regclass) NOT NULL,
    citation_id bigint,
    site_id bigint,
    specie_id bigint,
    treatment_id bigint,
    cultivar_id bigint,
    date date,
    dateloc numeric(4,2),
    statname statnames DEFAULT ''::text,
    stat double precision,
    mean double precision NOT NULL,
    n integer,
    notes text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    user_id bigint,
    checked integer DEFAULT 0 NOT NULL,
    access_level level_of_access,
    method_id bigint,
    entity_id bigint,
    date_year integer,
    date_month integer,
    date_day integer,
    CONSTRAINT valid_yield_checked_value CHECK (((checked >= (-1)) AND (checked <= 1)))
);


--
-- Name: COLUMN yields.citation_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.citation_id IS 'Citation in which data originally reported.';


--
-- Name: COLUMN yields.site_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.site_id IS 'Site at which crop was harvested.';


--
-- Name: COLUMN yields.specie_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.specie_id IS 'Species for which yield was measured.';


--
-- Name: COLUMN yields.treatment_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.treatment_id IS 'Experimental treatment identification. Required, can indicate observational study.';


--
-- Name: COLUMN yields.cultivar_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.cultivar_id IS 'Cultivar information, if any.';


--
-- Name: COLUMN yields.date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.date IS 'Date on which crop was harvested.';


--
-- Name: COLUMN yields.dateloc; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.dateloc IS 'Level of confidence in harvest date. See documentation.';


--
-- Name: COLUMN yields.statname; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.statname IS 'Name of reported statistic.';


--
-- Name: COLUMN yields.stat; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.stat IS 'Value of reported statistic.';


--
-- Name: COLUMN yields.mean; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.mean IS 'Mean yield reported. ';


--
-- Name: COLUMN yields.n; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.n IS 'Number of replicates used to estimate mean and statistical summary.';


--
-- Name: COLUMN yields.user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.user_id IS 'ID of user who entered data.';


--
-- Name: COLUMN yields.checked; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.checked IS 'accepts values [-1, 0, 1]. 0 is default, and means that data have not been checked. 1 indicates that the data have been checked and are correct, -1 indicates that data have been checked and found to be incorrect or suspicious, e.g. outside of the acceptab';


--
-- Name: COLUMN yields.access_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN yields.access_level IS 'Level of access required to view data.';


--
-- Name: yieldsview_private; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW yieldsview_private AS
 SELECT 'yields'::character(10) AS result_type,
    yields.id,
    yields.citation_id,
    yields.site_id,
    yields.treatment_id,
    sites.sitename,
    sites.city,
    st_y(st_centroid(sites.geometry)) AS lat,
    st_x(st_centroid(sites.geometry)) AS lon,
    species.scientificname,
    species.commonname,
    species.genus,
    species.id AS species_id,
    yields.cultivar_id,
    citations.author,
    citations.year AS citation_year,
    treatments.name AS treatment,
    yields.date,
    date_part('month'::text, yields.date) AS month,
    date_part('year'::text, yields.date) AS year,
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
   FROM ((((((yields
     LEFT JOIN sites ON ((yields.site_id = sites.id)))
     LEFT JOIN species ON ((yields.specie_id = species.id)))
     LEFT JOIN citations ON ((yields.citation_id = citations.id)))
     LEFT JOIN treatments ON ((yields.treatment_id = treatments.id)))
     LEFT JOIN variables ON (((variables.name)::text = 'Ayield'::text)))
     LEFT JOIN users ON ((yields.user_id = users.id)));


--
-- Name: traits_and_yields_view_private; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW traits_and_yields_view_private AS
 SELECT traitsview_private.result_type,
    traitsview_private.id,
    traitsview_private.citation_id,
    traitsview_private.site_id,
    traitsview_private.treatment_id,
    traitsview_private.sitename,
    traitsview_private.city,
    traitsview_private.lat,
    traitsview_private.lon,
    traitsview_private.scientificname,
    traitsview_private.commonname,
    traitsview_private.genus,
    traitsview_private.species_id,
    traitsview_private.cultivar_id,
    traitsview_private.author,
    traitsview_private.citation_year,
    traitsview_private.treatment,
    traitsview_private.date,
    traitsview_private.month,
    traitsview_private.year,
    traitsview_private.dateloc,
    traitsview_private.trait,
    traitsview_private.trait_description,
    traitsview_private.mean,
    traitsview_private.units,
    traitsview_private.n,
    traitsview_private.statname,
    traitsview_private.stat,
    traitsview_private.notes,
    traitsview_private.access_level,
    traitsview_private.checked,
    traitsview_private.login,
    traitsview_private.name,
    traitsview_private.email
   FROM traitsview_private
UNION ALL
 SELECT yieldsview_private.result_type,
    yieldsview_private.id,
    yieldsview_private.citation_id,
    yieldsview_private.site_id,
    yieldsview_private.treatment_id,
    yieldsview_private.sitename,
    yieldsview_private.city,
    yieldsview_private.lat,
    yieldsview_private.lon,
    yieldsview_private.scientificname,
    yieldsview_private.commonname,
    yieldsview_private.genus,
    yieldsview_private.species_id,
    yieldsview_private.cultivar_id,
    yieldsview_private.author,
    yieldsview_private.citation_year,
    yieldsview_private.treatment,
    yieldsview_private.date,
    yieldsview_private.month,
    yieldsview_private.year,
    yieldsview_private.dateloc,
    yieldsview_private.trait,
    yieldsview_private.trait_description,
    yieldsview_private.mean,
    yieldsview_private.units,
    yieldsview_private.n,
    yieldsview_private.statname,
    yieldsview_private.stat,
    yieldsview_private.notes,
    yieldsview_private.access_level,
    yieldsview_private.checked,
    yieldsview_private.login,
    yieldsview_private.name,
    yieldsview_private.email
   FROM yieldsview_private;


--
-- Name: traits_and_yields_view; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW traits_and_yields_view AS
 SELECT traits_and_yields_view_private.checked,
    traits_and_yields_view_private.result_type,
    traits_and_yields_view_private.id,
    traits_and_yields_view_private.citation_id,
    traits_and_yields_view_private.site_id,
    traits_and_yields_view_private.treatment_id,
    traits_and_yields_view_private.sitename,
    traits_and_yields_view_private.city,
    traits_and_yields_view_private.lat,
    traits_and_yields_view_private.lon,
    traits_and_yields_view_private.scientificname,
    traits_and_yields_view_private.commonname,
    traits_and_yields_view_private.genus,
    traits_and_yields_view_private.species_id,
    traits_and_yields_view_private.cultivar_id,
    traits_and_yields_view_private.author,
    traits_and_yields_view_private.citation_year,
    traits_and_yields_view_private.treatment,
    traits_and_yields_view_private.date,
    traits_and_yields_view_private.month,
    traits_and_yields_view_private.year,
    traits_and_yields_view_private.dateloc,
    traits_and_yields_view_private.trait,
    traits_and_yields_view_private.trait_description,
    traits_and_yields_view_private.mean,
    traits_and_yields_view_private.units,
    traits_and_yields_view_private.n,
    traits_and_yields_view_private.statname,
    traits_and_yields_view_private.stat,
    traits_and_yields_view_private.notes,
    traits_and_yields_view_private.access_level
   FROM traits_and_yields_view_private
  WHERE (traits_and_yields_view_private.checked >= 0);


--
-- Name: workflows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE workflows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflows; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE workflows (
    id bigint DEFAULT nextval('workflows_id_seq'::regclass) NOT NULL,
    folder character varying(255) NOT NULL,
    started_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now(),
    site_id bigint,
    model_id bigint NOT NULL,
    hostname character varying(255) NOT NULL,
    params text DEFAULT ''::text NOT NULL,
    advanced_edit boolean DEFAULT false NOT NULL,
    start_date timestamp(6) without time zone,
    end_date timestamp(6) without time zone,
    notes text,
    user_id bigint,
    CONSTRAINT normalized_workflow_folder_name CHECK (is_whitespace_normalized((folder)::text)),
    CONSTRAINT normalized_workflow_hostname CHECK (is_whitespace_normalized((hostname)::text)),
    CONSTRAINT normalized_workflow_params_value CHECK (is_whitespace_normalized(params))
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY citations_sites ALTER COLUMN id SET DEFAULT nextval('citations_sites_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY citations_treatments ALTER COLUMN id SET DEFAULT nextval('citations_treatments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_posteriors ALTER COLUMN id SET DEFAULT nextval('current_posteriors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY inputs_runs ALTER COLUMN id SET DEFAULT nextval('inputs_runs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY managements_treatments ALTER COLUMN id SET DEFAULT nextval('managements_treatments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY modeltypes ALTER COLUMN id SET DEFAULT nextval('modeltypes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY modeltypes_formats ALTER COLUMN id SET DEFAULT nextval('modeltypes_formats_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pfts_priors ALTER COLUMN id SET DEFAULT nextval('pfts_priors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pfts_species ALTER COLUMN id SET DEFAULT nextval('pfts_species_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY posterior_samples ALTER COLUMN id SET DEFAULT nextval('posterior_samples_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY posteriors_ensembles ALTER COLUMN id SET DEFAULT nextval('posteriors_ensembles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects ALTER COLUMN id SET DEFAULT nextval('projects_id_seq'::regclass);


--
-- Name: citations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY citations
    ADD CONSTRAINT citations_pkey PRIMARY KEY (id);


--
-- Name: covariates_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY covariates
    ADD CONSTRAINT covariates_pkey PRIMARY KEY (id);


--
-- Name: cultivars_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cultivars
    ADD CONSTRAINT cultivars_pkey PRIMARY KEY (id);


--
-- Name: current_posteriors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY current_posteriors
    ADD CONSTRAINT current_posteriors_pkey PRIMARY KEY (id);


--
-- Name: dbfiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dbfiles
    ADD CONSTRAINT dbfiles_pkey PRIMARY KEY (id);


--
-- Name: ensembles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ensembles
    ADD CONSTRAINT ensembles_pkey PRIMARY KEY (id);


--
-- Name: entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT entities_pkey PRIMARY KEY (id);


--
-- Name: formats_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY formats
    ADD CONSTRAINT formats_pkey PRIMARY KEY (id);


--
-- Name: formats_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY formats_variables
    ADD CONSTRAINT formats_variables_pkey PRIMARY KEY (id);


--
-- Name: inputs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY inputs
    ADD CONSTRAINT inputs_pkey PRIMARY KEY (id);


--
-- Name: likelihoods_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY likelihoods
    ADD CONSTRAINT likelihoods_pkey PRIMARY KEY (id);


--
-- Name: machines_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY machines
    ADD CONSTRAINT machines_pkey PRIMARY KEY (id);


--
-- Name: managements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY managements
    ADD CONSTRAINT managements_pkey PRIMARY KEY (id);


--
-- Name: methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY methods
    ADD CONSTRAINT methods_pkey PRIMARY KEY (id);


--
-- Name: mimetypes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mimetypes
    ADD CONSTRAINT mimetypes_pkey PRIMARY KEY (id);


--
-- Name: models_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY models
    ADD CONSTRAINT models_pkey PRIMARY KEY (id);


--
-- Name: modeltypes_formats_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY modeltypes_formats
    ADD CONSTRAINT modeltypes_formats_pkey PRIMARY KEY (id);


--
-- Name: modeltypes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY modeltypes
    ADD CONSTRAINT modeltypes_pkey PRIMARY KEY (id);


--
-- Name: pfts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pfts
    ADD CONSTRAINT pfts_pkey PRIMARY KEY (id);


--
-- Name: posterior_samples_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY posterior_samples
    ADD CONSTRAINT posterior_samples_pkey PRIMARY KEY (id);


--
-- Name: posteriors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY posteriors
    ADD CONSTRAINT posteriors_pkey PRIMARY KEY (id);


--
-- Name: priors_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY priors
    ADD CONSTRAINT priors_pkey PRIMARY KEY (id);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY runs
    ADD CONSTRAINT runs_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sites_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT sites_pkey PRIMARY KEY (id);


--
-- Name: species_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY species
    ADD CONSTRAINT species_pkey PRIMARY KEY (id);


--
-- Name: traits_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY traits
    ADD CONSTRAINT traits_pkey PRIMARY KEY (id);


--
-- Name: treatments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY treatments
    ADD CONSTRAINT treatments_pkey PRIMARY KEY (id);


--
-- Name: unique_filename_and_path_per_machine; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dbfiles
    ADD CONSTRAINT unique_filename_and_path_per_machine UNIQUE (file_name, file_path, machine_id);


--
-- Name: unique_hostnames; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY machines
    ADD CONSTRAINT unique_hostnames UNIQUE (hostname);


--
-- Name: unique_input_run_pair; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY inputs_runs
    ADD CONSTRAINT unique_input_run_pair UNIQUE (input_id, run_id);


--
-- Name: unique_name_per_model; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pfts
    ADD CONSTRAINT unique_name_per_model UNIQUE (name, modeltype_id);


--
-- Name: unique_name_per_species; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cultivars
    ADD CONSTRAINT unique_name_per_species UNIQUE (name, specie_id);


--
-- Name: unique_names_per_modeltype; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY pfts
    ADD CONSTRAINT unique_names_per_modeltype UNIQUE (name, modeltype_id);


--
-- Name: unique_run_variable_input_combination; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY likelihoods
    ADD CONSTRAINT unique_run_variable_input_combination UNIQUE (run_id, variable_id, input_id);


--
-- Name: unique_sync_host_id; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY machines
    ADD CONSTRAINT unique_sync_host_id UNIQUE (sync_host_id);


--
-- Name: unique_time_interval_per_model_site_parameter_list_and_ensemble; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY runs
    ADD CONSTRAINT unique_time_interval_per_model_site_parameter_list_and_ensemble UNIQUE (model_id, site_id, start_time, finish_time, parameter_list, ensemble_id);


--
-- Name: unique_type_string; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mimetypes
    ADD CONSTRAINT unique_type_string UNIQUE (type_string);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY variables
    ADD CONSTRAINT variables_pkey PRIMARY KEY (id);


--
-- Name: workflows_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT workflows_pkey PRIMARY KEY (id);


--
-- Name: yields_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY yields
    ADD CONSTRAINT yields_pkey PRIMARY KEY (id);


--
-- Name: cultivar_pft_uniqueness; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX cultivar_pft_uniqueness ON cultivars_pfts USING btree (pft_id, cultivar_id);


--
-- Name: index_citations_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_citations_on_user_id ON citations USING btree (user_id);


--
-- Name: index_citations_sites_on_citation_id_and_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_citations_sites_on_citation_id_and_site_id ON citations_sites USING btree (citation_id, site_id);


--
-- Name: index_citations_treatments_on_citation_id_and_treatment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_citations_treatments_on_citation_id_and_treatment_id ON citations_treatments USING btree (citation_id, treatment_id);


--
-- Name: index_covariates_on_trait_id_and_variable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_covariates_on_trait_id_and_variable_id ON covariates USING btree (trait_id, variable_id);


--
-- Name: index_cultivars_on_specie_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_cultivars_on_specie_id ON cultivars USING btree (specie_id);


--
-- Name: index_dbfiles_on_container_id_and_container_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_dbfiles_on_container_id_and_container_type ON dbfiles USING btree (container_type);


--
-- Name: index_dbfiles_on_created_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_dbfiles_on_created_user_id ON dbfiles USING btree (created_user_id);


--
-- Name: index_dbfiles_on_machine_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_dbfiles_on_machine_id ON dbfiles USING btree (machine_id);


--
-- Name: index_dbfiles_on_updated_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_dbfiles_on_updated_user_id ON dbfiles USING btree (updated_user_id);


--
-- Name: index_entities_on_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_entities_on_parent_id ON entities USING btree (parent_id);


--
-- Name: index_formats_variables_on_format_id_and_variable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_formats_variables_on_format_id_and_variable_id ON formats_variables USING btree (format_id, variable_id);


--
-- Name: index_inputs_on_format_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_inputs_on_format_id ON inputs USING btree (format_id);


--
-- Name: index_inputs_on_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_inputs_on_parent_id ON inputs USING btree (parent_id);


--
-- Name: index_inputs_on_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_inputs_on_site_id ON inputs USING btree (site_id);


--
-- Name: index_inputs_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_inputs_on_user_id ON inputs USING btree (user_id);


--
-- Name: index_inputs_runs_on_input_id_and_run_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_inputs_runs_on_input_id_and_run_id ON inputs_runs USING btree (input_id, run_id);


--
-- Name: index_likelihoods_on_input_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_likelihoods_on_input_id ON likelihoods USING btree (input_id);


--
-- Name: index_likelihoods_on_run_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_likelihoods_on_run_id ON likelihoods USING btree (run_id);


--
-- Name: index_likelihoods_on_variable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_likelihoods_on_variable_id ON likelihoods USING btree (variable_id);


--
-- Name: index_machines_on_hostname; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_machines_on_hostname ON machines USING btree (hostname);


--
-- Name: index_managements_on_citation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_managements_on_citation_id ON managements USING btree (citation_id);


--
-- Name: index_managements_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_managements_on_user_id ON managements USING btree (user_id);


--
-- Name: index_managements_treatments_on_management_id_and_treatment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_managements_treatments_on_management_id_and_treatment_id ON managements_treatments USING btree (management_id, treatment_id);


--
-- Name: index_methods_on_citation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_methods_on_citation_id ON methods USING btree (citation_id);


--
-- Name: index_models_on_parent_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_models_on_parent_id ON models USING btree (parent_id);


--
-- Name: index_modeltypes_formats_on_modeltype_id_and_tag; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_modeltypes_formats_on_modeltype_id_and_tag ON modeltypes_formats USING btree (modeltype_id, tag);


--
-- Name: index_modeltypes_formats_on_modeltype_id_format_id_input; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_modeltypes_formats_on_modeltype_id_format_id_input ON modeltypes_formats USING btree (modeltype_id, format_id, input);


--
-- Name: index_modeltypes_on_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_modeltypes_on_name ON modeltypes USING btree (name);


--
-- Name: index_pfts_priors_on_pft_id_and_prior_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_pfts_priors_on_pft_id_and_prior_id ON pfts_priors USING btree (pft_id, prior_id);


--
-- Name: index_pfts_species_on_pft_id_and_specie_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_pfts_species_on_pft_id_and_specie_id ON pfts_species USING btree (pft_id, specie_id);


--
-- Name: index_posteriors_on_pft_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_posteriors_on_pft_id ON posteriors USING btree (pft_id);


--
-- Name: index_priors_on_citation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_priors_on_citation_id ON priors USING btree (citation_id);


--
-- Name: index_priors_on_variable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_priors_on_variable_id ON priors USING btree (variable_id);


--
-- Name: index_runs_on_ensemble_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_runs_on_ensemble_id ON runs USING btree (ensemble_id);


--
-- Name: index_runs_on_model_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_runs_on_model_id ON runs USING btree (model_id);


--
-- Name: index_runs_on_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_runs_on_site_id ON runs USING btree (site_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_sites_on_geometry; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_geometry ON sites USING gist (geometry);


--
-- Name: index_sites_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_sites_on_user_id ON sites USING btree (user_id);


--
-- Name: index_traits_on_citation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_traits_on_citation_id ON traits USING btree (citation_id);


--
-- Name: index_traits_on_cultivar_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_traits_on_cultivar_id ON traits USING btree (cultivar_id);


--
-- Name: index_traits_on_entity_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_traits_on_entity_id ON traits USING btree (entity_id);


--
-- Name: index_traits_on_method_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_traits_on_method_id ON traits USING btree (method_id);


--
-- Name: index_traits_on_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_traits_on_site_id ON traits USING btree (site_id);


--
-- Name: index_traits_on_specie_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_traits_on_specie_id ON traits USING btree (specie_id);


--
-- Name: index_traits_on_treatment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_traits_on_treatment_id ON traits USING btree (treatment_id);


--
-- Name: index_traits_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_traits_on_user_id ON traits USING btree (user_id);


--
-- Name: index_traits_on_variable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_traits_on_variable_id ON traits USING btree (variable_id);


--
-- Name: index_treatments_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_treatments_on_user_id ON treatments USING btree (user_id);


--
-- Name: index_users_on_login; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_login ON users USING btree (login);


--
-- Name: index_yields_on_citation_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_yields_on_citation_id ON yields USING btree (citation_id);


--
-- Name: index_yields_on_cultivar_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_yields_on_cultivar_id ON yields USING btree (cultivar_id);


--
-- Name: index_yields_on_method_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_yields_on_method_id ON yields USING btree (method_id);


--
-- Name: index_yields_on_site_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_yields_on_site_id ON yields USING btree (site_id);


--
-- Name: index_yields_on_specie_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_yields_on_specie_id ON yields USING btree (specie_id);


--
-- Name: index_yields_on_treatment_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_yields_on_treatment_id ON yields USING btree (treatment_id);


--
-- Name: index_yields_on_user_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_yields_on_user_id ON yields USING btree (user_id);


--
-- Name: trait_covariate_associations_uniqueness; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX trait_covariate_associations_uniqueness ON trait_covariate_associations USING btree (trait_variable_id, covariate_variable_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: forbid_dangling_input_references; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER forbid_dangling_input_references BEFORE DELETE OR UPDATE ON inputs FOR EACH ROW EXECUTE PROCEDURE forbid_dangling_input_references();


--
-- Name: forbid_dangling_model_references; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER forbid_dangling_model_references BEFORE DELETE OR UPDATE ON models FOR EACH ROW EXECUTE PROCEDURE forbid_dangling_model_references();


--
-- Name: forbid_dangling_posterior_references; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER forbid_dangling_posterior_references BEFORE DELETE OR UPDATE ON posteriors FOR EACH ROW EXECUTE PROCEDURE forbid_dangling_posterior_references();


--
-- Name: forbid_truncating_input_referents; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER forbid_truncating_input_referents AFTER TRUNCATE ON inputs FOR EACH STATEMENT EXECUTE PROCEDURE check_for_references('Input');


--
-- Name: forbid_truncating_model_referents; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER forbid_truncating_model_referents AFTER TRUNCATE ON models FOR EACH STATEMENT EXECUTE PROCEDURE check_for_references('Model');


--
-- Name: forbid_truncating_posterior_referents; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER forbid_truncating_posterior_referents AFTER TRUNCATE ON posteriors FOR EACH STATEMENT EXECUTE PROCEDURE check_for_references('Posterior');


--
-- Name: normalize_cross; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER normalize_cross BEFORE INSERT OR UPDATE OF species, scientificname ON species FOR EACH ROW WHEN ((((new.species)::text ~ ' x '::text) OR ((new.scientificname)::text ~ ' x '::text))) EXECUTE PROCEDURE replace_x();


--
-- Name: normalize_cultivar_names; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER normalize_cultivar_names BEFORE INSERT OR UPDATE ON cultivars FOR EACH ROW EXECUTE PROCEDURE normalize_name_whitespace();


--
-- Name: prevent_conflicting_range_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER prevent_conflicting_range_changes BEFORE UPDATE OF min, max ON variables FOR EACH ROW EXECUTE PROCEDURE prevent_conflicting_range_changes();


--
-- Name: TRIGGER prevent_conflicting_range_changes ON variables; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TRIGGER prevent_conflicting_range_changes ON variables IS 'Trigger function to ensure that updates to the min or max values in
   the variables table do not cause any existing trait or covariate
   values to be out of range.';


--
-- Name: restrict_covariate_range; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER restrict_covariate_range BEFORE INSERT OR UPDATE ON covariates FOR EACH ROW EXECUTE PROCEDURE restrict_covariate_range();


--
-- Name: TRIGGER restrict_covariate_range ON covariates; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TRIGGER restrict_covariate_range ON covariates IS 'Trigger function to ensure values of level in the covariates table
   are within the range specified by min and max in the variables
   table.  A NULL in the min or max column means "no limit".';


--
-- Name: restrict_trait_range; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER restrict_trait_range BEFORE INSERT OR UPDATE ON traits FOR EACH ROW EXECUTE PROCEDURE restrict_trait_range();


--
-- Name: TRIGGER restrict_trait_range ON traits; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TRIGGER restrict_trait_range ON traits IS 'Trigger function to ensure values of mean in the traits table are
   within the range specified by min and max in the variables table.
   A NULL in the min or max column means "no limit".';


--
-- Name: update_citations_sites_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_citations_sites_timestamp BEFORE UPDATE ON citations_sites FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_citations_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_citations_timestamp BEFORE UPDATE ON citations FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_citations_treatments_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_citations_treatments_timestamp BEFORE UPDATE ON citations_treatments FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_covariates_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_covariates_timestamp BEFORE UPDATE ON covariates FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_cultivars_pfts_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_cultivars_pfts_timestamp BEFORE UPDATE ON cultivars_pfts FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_cultivars_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_cultivars_timestamp BEFORE UPDATE ON cultivars FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_current_posteriors_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_current_posteriors_timestamp BEFORE UPDATE ON current_posteriors FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_dbfiles_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_dbfiles_timestamp BEFORE UPDATE ON dbfiles FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_ensembles_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_ensembles_timestamp BEFORE UPDATE ON ensembles FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_entities_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_entities_timestamp BEFORE UPDATE ON entities FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_formats_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_formats_timestamp BEFORE UPDATE ON formats FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_formats_variables_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_formats_variables_timestamp BEFORE UPDATE ON formats_variables FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_inputs_runs_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_inputs_runs_timestamp BEFORE UPDATE ON inputs_runs FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_inputs_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_inputs_timestamp BEFORE UPDATE ON inputs FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_likelihoods_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_likelihoods_timestamp BEFORE UPDATE ON likelihoods FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_machines_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_machines_timestamp BEFORE UPDATE ON machines FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_managements_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_managements_timestamp BEFORE UPDATE ON managements FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_managements_treatments_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_managements_treatments_timestamp BEFORE UPDATE ON managements_treatments FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_methods_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_methods_timestamp BEFORE UPDATE ON methods FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_models_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_models_timestamp BEFORE UPDATE ON models FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_modeltypes_formats_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_modeltypes_formats_timestamp BEFORE UPDATE ON modeltypes_formats FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_modeltypes_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_modeltypes_timestamp BEFORE UPDATE ON modeltypes FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_pfts_priors_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_pfts_priors_timestamp BEFORE UPDATE ON pfts_priors FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_pfts_species_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_pfts_species_timestamp BEFORE UPDATE ON pfts_species FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_pfts_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_pfts_timestamp BEFORE UPDATE ON pfts FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_posterior_samples_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_posterior_samples_timestamp BEFORE UPDATE ON posterior_samples FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_posteriors_ensembles_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_posteriors_ensembles_timestamp BEFORE UPDATE ON posteriors_ensembles FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_posteriors_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_posteriors_timestamp BEFORE UPDATE ON posteriors FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_priors_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_priors_timestamp BEFORE UPDATE ON priors FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_projects_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_projects_timestamp BEFORE UPDATE ON projects FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_runs_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_runs_timestamp BEFORE UPDATE ON runs FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_sessions_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_sessions_timestamp BEFORE UPDATE ON sessions FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_sites_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_sites_timestamp BEFORE UPDATE ON sites FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_species_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_species_timestamp BEFORE UPDATE ON species FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_traits_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_traits_timestamp BEFORE UPDATE ON traits FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_treatments_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_treatments_timestamp BEFORE UPDATE ON treatments FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_users_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_users_timestamp BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_variables_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_variables_timestamp BEFORE UPDATE ON variables FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_workflows_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_workflows_timestamp BEFORE UPDATE ON workflows FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: update_yields_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_yields_timestamp BEFORE UPDATE ON yields FOR EACH ROW EXECUTE PROCEDURE update_timestamp();


--
-- Name: cultivar_exists; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cultivars_pfts
    ADD CONSTRAINT cultivar_exists FOREIGN KEY (cultivar_id) REFERENCES cultivars(id) ON UPDATE CASCADE;


--
-- Name: CONSTRAINT cultivar_exists ON cultivars_pfts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT cultivar_exists ON cultivars_pfts IS 'Ensure the referred-to cultivar exists, block its deletion if it is being used in a pft, and update the reference if the cultivar id number changes.';


--
-- Name: fk_citations_sites_citations_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY citations_sites
    ADD CONSTRAINT fk_citations_sites_citations_1 FOREIGN KEY (citation_id) REFERENCES citations(id) ON DELETE CASCADE;


--
-- Name: fk_citations_sites_sites_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY citations_sites
    ADD CONSTRAINT fk_citations_sites_sites_1 FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE RESTRICT;


--
-- Name: fk_citations_treatments_citations_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY citations_treatments
    ADD CONSTRAINT fk_citations_treatments_citations_1 FOREIGN KEY (citation_id) REFERENCES citations(id) ON DELETE CASCADE;


--
-- Name: fk_citations_treatments_treatments_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY citations_treatments
    ADD CONSTRAINT fk_citations_treatments_treatments_1 FOREIGN KEY (treatment_id) REFERENCES treatments(id) ON DELETE CASCADE;


--
-- Name: fk_citations_users_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY citations
    ADD CONSTRAINT fk_citations_users_1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_covariates_variables_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY covariates
    ADD CONSTRAINT fk_covariates_variables_1 FOREIGN KEY (variable_id) REFERENCES variables(id);


--
-- Name: fk_cultivars_species_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cultivars
    ADD CONSTRAINT fk_cultivars_species_1 FOREIGN KEY (specie_id) REFERENCES species(id);


--
-- Name: fk_current_posteriors_pfts_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_posteriors
    ADD CONSTRAINT fk_current_posteriors_pfts_1 FOREIGN KEY (pft_id) REFERENCES pfts(id);


--
-- Name: fk_current_posteriors_posterior_samples_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_posteriors
    ADD CONSTRAINT fk_current_posteriors_posterior_samples_1 FOREIGN KEY (posteriors_samples_id) REFERENCES posterior_samples(id);


--
-- Name: fk_current_posteriors_projects_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_posteriors
    ADD CONSTRAINT fk_current_posteriors_projects_1 FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: fk_current_posteriors_variables_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_posteriors
    ADD CONSTRAINT fk_current_posteriors_variables_1 FOREIGN KEY (variable_id) REFERENCES variables(id);


--
-- Name: fk_dbfiles_machines_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dbfiles
    ADD CONSTRAINT fk_dbfiles_machines_1 FOREIGN KEY (machine_id) REFERENCES machines(id);


--
-- Name: fk_dbfiles_users_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dbfiles
    ADD CONSTRAINT fk_dbfiles_users_1 FOREIGN KEY (created_user_id) REFERENCES users(id);


--
-- Name: fk_dbfiles_users_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY dbfiles
    ADD CONSTRAINT fk_dbfiles_users_2 FOREIGN KEY (updated_user_id) REFERENCES users(id);


--
-- Name: fk_ensembles_workflows_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ensembles
    ADD CONSTRAINT fk_ensembles_workflows_1 FOREIGN KEY (workflow_id) REFERENCES workflows(id);


--
-- Name: fk_entities_entities_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY entities
    ADD CONSTRAINT fk_entities_entities_1 FOREIGN KEY (parent_id) REFERENCES entities(id);


--
-- Name: fk_formats_variables_formats_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY formats_variables
    ADD CONSTRAINT fk_formats_variables_formats_1 FOREIGN KEY (format_id) REFERENCES formats(id) ON DELETE CASCADE;


--
-- Name: fk_formats_variables_variables_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY formats_variables
    ADD CONSTRAINT fk_formats_variables_variables_1 FOREIGN KEY (variable_id) REFERENCES variables(id) ON DELETE CASCADE;


--
-- Name: fk_inputs_formats_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inputs
    ADD CONSTRAINT fk_inputs_formats_1 FOREIGN KEY (format_id) REFERENCES formats(id);


--
-- Name: fk_inputs_inputs_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inputs
    ADD CONSTRAINT fk_inputs_inputs_1 FOREIGN KEY (parent_id) REFERENCES inputs(id);


--
-- Name: fk_inputs_runs_inputs_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inputs_runs
    ADD CONSTRAINT fk_inputs_runs_inputs_1 FOREIGN KEY (input_id) REFERENCES inputs(id) ON DELETE CASCADE;


--
-- Name: fk_inputs_runs_runs_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inputs_runs
    ADD CONSTRAINT fk_inputs_runs_runs_1 FOREIGN KEY (run_id) REFERENCES runs(id) ON DELETE CASCADE;


--
-- Name: fk_inputs_sites_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inputs
    ADD CONSTRAINT fk_inputs_sites_1 FOREIGN KEY (site_id) REFERENCES sites(id);


--
-- Name: fk_inputs_users_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inputs
    ADD CONSTRAINT fk_inputs_users_1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_likelihoods_inputs_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY likelihoods
    ADD CONSTRAINT fk_likelihoods_inputs_1 FOREIGN KEY (input_id) REFERENCES inputs(id);


--
-- Name: fk_likelihoods_runs_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY likelihoods
    ADD CONSTRAINT fk_likelihoods_runs_1 FOREIGN KEY (run_id) REFERENCES runs(id);


--
-- Name: fk_likelihoods_variables_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY likelihoods
    ADD CONSTRAINT fk_likelihoods_variables_1 FOREIGN KEY (variable_id) REFERENCES variables(id);


--
-- Name: fk_managements_citations_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY managements
    ADD CONSTRAINT fk_managements_citations_1 FOREIGN KEY (citation_id) REFERENCES citations(id);


--
-- Name: fk_managements_treatments_managements_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY managements_treatments
    ADD CONSTRAINT fk_managements_treatments_managements_1 FOREIGN KEY (management_id) REFERENCES managements(id) ON DELETE CASCADE;


--
-- Name: fk_managements_treatments_treatments_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY managements_treatments
    ADD CONSTRAINT fk_managements_treatments_treatments_1 FOREIGN KEY (treatment_id) REFERENCES treatments(id) ON DELETE CASCADE;


--
-- Name: fk_managements_users_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY managements
    ADD CONSTRAINT fk_managements_users_1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_methods_citations_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY methods
    ADD CONSTRAINT fk_methods_citations_1 FOREIGN KEY (citation_id) REFERENCES citations(id);


--
-- Name: fk_models_models_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY models
    ADD CONSTRAINT fk_models_models_1 FOREIGN KEY (parent_id) REFERENCES models(id);


--
-- Name: fk_models_modeltypes_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY models
    ADD CONSTRAINT fk_models_modeltypes_1 FOREIGN KEY (modeltype_id) REFERENCES modeltypes(id);


--
-- Name: fk_modeltypes_formats_formats_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY modeltypes_formats
    ADD CONSTRAINT fk_modeltypes_formats_formats_1 FOREIGN KEY (format_id) REFERENCES formats(id) ON DELETE CASCADE;


--
-- Name: fk_modeltypes_formats_modeltypes_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY modeltypes_formats
    ADD CONSTRAINT fk_modeltypes_formats_modeltypes_1 FOREIGN KEY (modeltype_id) REFERENCES modeltypes(id) ON DELETE CASCADE;


--
-- Name: fk_modeltypes_formats_users_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY modeltypes_formats
    ADD CONSTRAINT fk_modeltypes_formats_users_1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_modeltypes_users_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY modeltypes
    ADD CONSTRAINT fk_modeltypes_users_1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_pfts_modeltypes_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pfts
    ADD CONSTRAINT fk_pfts_modeltypes_1 FOREIGN KEY (modeltype_id) REFERENCES modeltypes(id);


--
-- Name: fk_pfts_pfts_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pfts
    ADD CONSTRAINT fk_pfts_pfts_1 FOREIGN KEY (parent_id) REFERENCES pfts(id);


--
-- Name: fk_posterior_samples_pfts_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posterior_samples
    ADD CONSTRAINT fk_posterior_samples_pfts_1 FOREIGN KEY (pft_id) REFERENCES pfts(id);


--
-- Name: fk_posterior_samples_posterior_samples_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posterior_samples
    ADD CONSTRAINT fk_posterior_samples_posterior_samples_1 FOREIGN KEY (parent_id) REFERENCES posterior_samples(id);


--
-- Name: fk_posterior_samples_posteriors_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posterior_samples
    ADD CONSTRAINT fk_posterior_samples_posteriors_1 FOREIGN KEY (posterior_id) REFERENCES posteriors(id);


--
-- Name: fk_posterior_samples_variables_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posterior_samples
    ADD CONSTRAINT fk_posterior_samples_variables_1 FOREIGN KEY (variable_id) REFERENCES variables(id);


--
-- Name: fk_posteriors_ensembles_ensembles_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posteriors_ensembles
    ADD CONSTRAINT fk_posteriors_ensembles_ensembles_1 FOREIGN KEY (ensemble_id) REFERENCES ensembles(id) ON DELETE CASCADE;


--
-- Name: fk_posteriors_ensembles_posteriors_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posteriors_ensembles
    ADD CONSTRAINT fk_posteriors_ensembles_posteriors_1 FOREIGN KEY (posterior_id) REFERENCES posteriors(id) ON DELETE CASCADE;


--
-- Name: fk_posteriors_pfts_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY posteriors
    ADD CONSTRAINT fk_posteriors_pfts_1 FOREIGN KEY (pft_id) REFERENCES pfts(id);


--
-- Name: fk_priors_citations_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY priors
    ADD CONSTRAINT fk_priors_citations_1 FOREIGN KEY (citation_id) REFERENCES citations(id);


--
-- Name: fk_priors_variables_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY priors
    ADD CONSTRAINT fk_priors_variables_1 FOREIGN KEY (variable_id) REFERENCES variables(id);


--
-- Name: fk_projects_machines_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT fk_projects_machines_1 FOREIGN KEY (machine_id) REFERENCES machines(id);


--
-- Name: fk_runs_ensembles_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY runs
    ADD CONSTRAINT fk_runs_ensembles_1 FOREIGN KEY (ensemble_id) REFERENCES ensembles(id);


--
-- Name: fk_runs_models_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY runs
    ADD CONSTRAINT fk_runs_models_1 FOREIGN KEY (model_id) REFERENCES models(id);


--
-- Name: fk_runs_sites_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY runs
    ADD CONSTRAINT fk_runs_sites_1 FOREIGN KEY (site_id) REFERENCES sites(id);


--
-- Name: fk_sites_users_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY sites
    ADD CONSTRAINT fk_sites_users_1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_trait_covariate_associations_variables_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trait_covariate_associations
    ADD CONSTRAINT fk_trait_covariate_associations_variables_1 FOREIGN KEY (covariate_variable_id) REFERENCES variables(id);


--
-- Name: fk_trait_covariate_associations_variables_2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trait_covariate_associations
    ADD CONSTRAINT fk_trait_covariate_associations_variables_2 FOREIGN KEY (trait_variable_id) REFERENCES variables(id);


--
-- Name: fk_workflows_models_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT fk_workflows_models_1 FOREIGN KEY (model_id) REFERENCES models(id);


--
-- Name: fk_workflows_sites_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT fk_workflows_sites_1 FOREIGN KEY (site_id) REFERENCES sites(id);


--
-- Name: fk_workflows_users_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY workflows
    ADD CONSTRAINT fk_workflows_users_1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_yields_citations_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY yields
    ADD CONSTRAINT fk_yields_citations_1 FOREIGN KEY (citation_id) REFERENCES citations(id);


--
-- Name: fk_yields_cultivars_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY yields
    ADD CONSTRAINT fk_yields_cultivars_1 FOREIGN KEY (cultivar_id) REFERENCES cultivars(id);


--
-- Name: fk_yields_methods_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY yields
    ADD CONSTRAINT fk_yields_methods_1 FOREIGN KEY (method_id) REFERENCES methods(id);


--
-- Name: fk_yields_species_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY yields
    ADD CONSTRAINT fk_yields_species_1 FOREIGN KEY (specie_id) REFERENCES species(id);


--
-- Name: fk_yields_treatments_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY yields
    ADD CONSTRAINT fk_yields_treatments_1 FOREIGN KEY (treatment_id) REFERENCES treatments(id);


--
-- Name: fk_yields_users_1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY yields
    ADD CONSTRAINT fk_yields_users_1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: pft_exists; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cultivars_pfts
    ADD CONSTRAINT pft_exists FOREIGN KEY (pft_id) REFERENCES pfts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: CONSTRAINT pft_exists ON cultivars_pfts; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT pft_exists ON cultivars_pfts IS 'Ensure the referred-to pft exists, and clean up any references to it if it is deleted or updated.';


--
-- Name: pft_exists; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pfts_species
    ADD CONSTRAINT pft_exists FOREIGN KEY (pft_id) REFERENCES pfts(id) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- Name: CONSTRAINT pft_exists ON pfts_species; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT pft_exists ON pfts_species IS 'Ensure the referred-to pft exists, and clean up any references to it if it is deleted or updated.';


--
-- Name: species_exists; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pfts_species
    ADD CONSTRAINT species_exists FOREIGN KEY (specie_id) REFERENCES species(id) ON UPDATE CASCADE NOT VALID;


--
-- Name: CONSTRAINT species_exists ON pfts_species; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON CONSTRAINT species_exists ON pfts_species IS 'Ensure the referred-to species exists, block its deletion if it is used in a pft, and update the reference if the species id number changes.';


--
-- PostgreSQL database dump complete
--

