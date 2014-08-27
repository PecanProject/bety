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
            RAISE EXCEPTION 'There are traits having values that are greater than % and traits having values that are less than %.', NEW.max, NEW.min;
        ELSE
            RAISE EXCEPTION 'There are traits having values that are less than %.', NEW.min;
        END IF;
    ELSE
        IF
            NEW.max::float < max
        THEN
            RAISE EXCEPTION 'There are traits having values that are greater than % .', NEW.max;
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
            RAISE EXCEPTION 'There are covariates having values that are greater than % and covariates having values that are less than %.', NEW.max, NEW.min;
        ELSE
            RAISE EXCEPTION 'There are covariates having values that are less than %.', NEW.min;
        END IF;
    ELSE
        IF
            NEW.max::float < max
        THEN
            RAISE EXCEPTION 'There are covariates having values that are greater than % .', NEW.max;
        END IF;
    END IF;        

    RETURN NEW ;
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
    author character varying(255),
    year integer,
    title character varying(255),
    journal character varying(255),
    vol integer,
    pg character varying(255),
    url character varying(512),
    pdf character varying(255),
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    doi character varying(255),
    user_id bigint
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
    citation_id bigint,
    site_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
);


--
-- Name: citations_treatments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE citations_treatments (
    citation_id bigint,
    treatment_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
);


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
-- Name: counties; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE counties (
    id bigint DEFAULT nextval('counties_id_seq'::regclass) NOT NULL,
    name character varying(255),
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    state character varying(255),
    state_fips integer,
    county_fips integer
);


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
    level numeric(16,4),
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    n integer,
    statname character varying(255),
    stat numeric(16,4)
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
    specie_id bigint,
    name character varying(255),
    ecotype character varying(255),
    notes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    previous_id character varying(255)
);


--
-- Name: COLUMN cultivars.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN cultivars.name IS 'Cultivar name given by breeder or reported in citation.';


--
-- Name: COLUMN cultivars.ecotype; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN cultivars.ecotype IS 'Does not apply for all species, used in the case of switchgrass to differentiate lowland and upland genotypes.';


--
-- Name: current_posteriors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE current_posteriors (
    id bigint NOT NULL,
    pft_id bigint,
    variable_id bigint,
    posteriors_samples_id bigint,
    project_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


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
    file_name character varying(255),
    file_path character varying(255),
    md5 character varying(255),
    created_user_id bigint,
    updated_user_id bigint,
    machine_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    container_type character varying(255),
    container_id bigint
);


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
    notes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    runtype character varying(255),
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
    name character varying(255),
    notes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
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
    mime_type character varying(255),
    dataformat text,
    notes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    name character varying(255),
    header character varying(255),
    skip character varying(255)
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
    format_id bigint,
    variable_id bigint,
    name character varying(255),
    unit character varying(255),
    storage_type character varying(255),
    column_number integer,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
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
    notes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    start_date timestamp(6) without time zone,
    end_date timestamp(6) without time zone,
    name character varying(255),
    parent_id bigint,
    user_id bigint,
    access_level integer,
    raw boolean,
    format_id bigint
);


--
-- Name: inputs_runs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE inputs_runs (
    input_id bigint,
    run_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
);


--
-- Name: inputs_variables; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE inputs_variables (
    input_id bigint,
    variable_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
);


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
    run_id bigint,
    variable_id bigint,
    input_id bigint,
    loglikelihood numeric(10,0),
    n_eff numeric(10,0),
    weight numeric(10,0),
    residual numeric(10,0),
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
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
-- Name: location_yields; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE location_yields (
    id bigint DEFAULT nextval('location_yields_id_seq'::regclass) NOT NULL,
    yield numeric(20,15),
    species character varying(255),
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    county_id bigint
);


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
    hostname character varying(255),
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
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
    mgmttype character varying(255),
    level numeric(16,4),
    units character varying(255),
    notes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
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
    treatment_id bigint,
    management_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
);


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
    name character varying(255),
    description text,
    citation_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
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
    type_string character varying(255)
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
    model_name character varying(255),
    revision character varying(255),
    parent_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    modeltype_id bigint NOT NULL
);


--
-- Name: modeltypes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE modeltypes (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: modeltypes_formats; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE modeltypes_formats (
    id bigint NOT NULL,
    modeltype_id bigint NOT NULL,
    tag character varying(255) NOT NULL,
    format_id bigint NOT NULL,
    required boolean DEFAULT false,
    input boolean DEFAULT true,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
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
    definition text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    name character varying(255),
    parent_id bigint,
    pft_type character varying(255) DEFAULT 'plant'::character varying,
    modeltype_id bigint NOT NULL
);


--
-- Name: COLUMN pfts.definition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pfts.definition IS 'Defines the creator and context under which the pft will be used.';


--
-- Name: COLUMN pfts.name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN pfts.name IS 'unique identifier used by PEcAn.';


--
-- Name: pfts_priors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pfts_priors (
    pft_id bigint,
    prior_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
);


--
-- Name: pfts_species; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE pfts_species (
    pft_id bigint,
    specie_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
);


--
-- Name: posterior_samples; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE posterior_samples (
    id bigint NOT NULL,
    posterior_id bigint,
    variable_id bigint,
    pft_id bigint,
    parent_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


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
    pft_id bigint,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    format_id bigint
);


--
-- Name: posteriors_ensembles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE posteriors_ensembles (
    posterior_id bigint,
    ensemble_id bigint,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


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
    variable_id bigint,
    phylogeny character varying(255),
    distn character varying(255),
    parama numeric(16,4),
    paramb numeric(16,4),
    paramc numeric(16,4),
    n integer,
    notes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
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
    name character varying(255),
    outdir character varying(255),
    machine_id bigint,
    description character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


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
    model_id bigint,
    site_id bigint,
    start_time timestamp(6) without time zone,
    finish_time timestamp(6) without time zone,
    outdir character varying(255),
    outprefix character varying(255),
    setting character varying(255),
    parameter_list text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    started_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    ensemble_id bigint,
    start_date character varying(255),
    end_date character varying(255)
);


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
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone
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
    city character varying(255),
    state character varying(255),
    country character varying(255),
    mat numeric(4,2),
    map integer,
    soil character varying(255),
    som numeric(4,2),
    notes text,
    soilnotes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    sitename character varying(255),
    greenhouse boolean,
    user_id bigint,
    local_time integer,
    sand_pct numeric(9,5),
    clay_pct numeric(9,5),
    geometry geometry(GeometryZ,4326)
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
    genus character varying(255),
    species character varying(255),
    scientificname character varying(255),
    commonname character varying(255),
    notes character varying(255),
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
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
    "SeedlingVigor" character varying(255)
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
    mean numeric(16,4),
    n integer,
    statname character varying(255),
    stat numeric(16,4),
    notes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    variable_id bigint,
    user_id bigint,
    checked integer,
    access_level integer,
    entity_id bigint,
    method_id bigint,
    date_year integer,
    date_month integer,
    date_day integer,
    time_hour integer,
    time_minute integer
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
    name character varying(255),
    definition character varying(255),
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    control boolean,
    user_id bigint
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
    login character varying(40),
    name character varying(100),
    email character varying(100),
    city character varying(255),
    country character varying(255),
    area character varying(255),
    crypted_password character varying(40),
    salt character varying(40),
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    remember_token character varying(40),
    remember_token_expires_at timestamp(6) without time zone,
    access_level integer,
    page_access_level integer,
    apikey character varying(255),
    state_prov character varying(255),
    postal_code character varying(255)
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
    description character varying(255),
    units character varying(255),
    notes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    name character varying(255),
    max character varying(255),
    min character varying(255),
    standard_name character varying(255),
    standard_units character varying(255),
    label character varying(255),
    type character varying(255)
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
    st_y(sites.geometry) AS lat,
    st_x(sites.geometry) AS lon,
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
    statname character varying(255),
    stat numeric(16,4),
    mean numeric(16,4),
    n integer,
    notes text,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    user_id bigint,
    checked integer,
    access_level integer,
    method_id bigint
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
    st_y(sites.geometry) AS lat,
    st_x(sites.geometry) AS lon,
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
 SELECT traits_and_yields_view_private.result_type,
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
  WHERE (traits_and_yields_view_private.checked > 0);


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
    folder character varying(255),
    started_at timestamp(6) without time zone,
    finished_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone,
    site_id bigint,
    model_id bigint NOT NULL,
    hostname character varying(255),
    params text,
    advanced_edit boolean DEFAULT false,
    start_date timestamp(6) without time zone,
    end_date timestamp(6) without time zone
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY current_posteriors ALTER COLUMN id SET DEFAULT nextval('current_posteriors_id_seq'::regclass);


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

ALTER TABLE ONLY posterior_samples ALTER COLUMN id SET DEFAULT nextval('posterior_samples_id_seq'::regclass);


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
-- Name: counties_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY counties
    ADD CONSTRAINT counties_pkey PRIMARY KEY (id);


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
-- Name: location_yields_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY location_yields
    ADD CONSTRAINT location_yields_pkey PRIMARY KEY (id);


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
-- Name: index_formats_on_mime_type; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_formats_on_mime_type ON formats USING btree (mime_type);


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
-- Name: index_inputs_variables_on_input_id_and_variable_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_inputs_variables_on_input_id_and_variable_id ON inputs_variables USING btree (input_id, variable_id);


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
-- Name: index_location_yields_on_county_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_location_yields_on_county_id ON location_yields USING btree (county_id);


--
-- Name: index_location_yields_on_location_and_species; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_location_yields_on_location_and_species ON location_yields USING btree (species);


--
-- Name: index_location_yields_on_species_and_county_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_location_yields_on_species_and_county_id ON location_yields USING btree (species, county_id);


--
-- Name: index_location_yields_on_yield; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX index_location_yields_on_yield ON location_yields USING btree (yield);


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
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: prevent_conflicting_range_changes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER prevent_conflicting_range_changes BEFORE UPDATE ON variables FOR EACH ROW EXECUTE PROCEDURE prevent_conflicting_range_changes();


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
-- PostgreSQL database dump complete
--

