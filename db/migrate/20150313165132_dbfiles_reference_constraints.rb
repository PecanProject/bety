class DbfilesReferenceConstraints < ActiveRecord::Migration
  def self.up

    execute %q{

/* dbfiles */

CREATE OR REPLACE FUNCTION get_input_ids(
) RETURNS int[] AS $$
DECLARE
    id_array int[];
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
) RETURNS int[] AS $$
DECLARE
    id_array int[];
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
) RETURNS int[] AS $$
DECLARE
    id_array int[];
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


ALTER TABLE dbfiles ADD CONSTRAINT valid_input_refs CHECK (container_type != 'Input' OR container_id = ANY(get_input_ids()));
ALTER TABLE dbfiles ADD CONSTRAINT valid_model_refs CHECK (container_type != 'Model' OR container_id = ANY(get_model_ids()));
ALTER TABLE dbfiles ADD CONSTRAINT valid_posterior_refs CHECK (container_type != 'Posterior' OR container_id = ANY(get_posterior_ids()));


/* Used for truncate triggers for inputs, models, and posteriors: */

CREATE OR REPLACE FUNCTION check_for_references() RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;


/* inputs */

CREATE OR REPLACE FUNCTION forbid_dangling_input_references() RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS forbid_dangling_input_references ON inputs;
CREATE TRIGGER forbid_dangling_input_references
    BEFORE UPDATE OR DELETE ON inputs
FOR EACH ROW
    EXECUTE PROCEDURE forbid_dangling_input_references();

DROP TRIGGER IF EXISTS forbid_truncating_input_referents ON inputs;
CREATE TRIGGER forbid_truncating_input_referents
    AFTER TRUNCATE ON inputs
FOR EACH STATEMENT
    EXECUTE PROCEDURE check_for_references('Input');
    


/* models */

CREATE OR REPLACE FUNCTION forbid_dangling_model_references() RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS forbid_dangling_model_references ON models;
CREATE TRIGGER forbid_dangling_model_references
    BEFORE UPDATE OR DELETE ON models
FOR EACH ROW
    EXECUTE PROCEDURE forbid_dangling_model_references();


DROP TRIGGER IF EXISTS forbid_truncating_model_referents ON models;
CREATE TRIGGER forbid_truncating_model_referents
    AFTER TRUNCATE ON models
FOR EACH STATEMENT
    EXECUTE PROCEDURE check_for_references('Model');
    


/* posteriors */

CREATE OR REPLACE FUNCTION forbid_dangling_posterior_references() RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS forbid_dangling_posterior_references ON posteriors;
CREATE TRIGGER forbid_dangling_posterior_references
    BEFORE UPDATE OR DELETE ON posteriors
FOR EACH ROW
    EXECUTE PROCEDURE forbid_dangling_posterior_references();

    
DROP TRIGGER IF EXISTS forbid_truncating_posterior_referents ON posteriors;
CREATE TRIGGER forbid_truncating_posterior_referents
    AFTER TRUNCATE ON posteriors
FOR EACH STATEMENT
    EXECUTE PROCEDURE check_for_references('Posterior');
    
    }

  end

  def self.down

    execute %q{

/* CASCADE drops the associated CHECK constraints: */
DROP FUNCTION get_input_ids() CASCADE;
DROP FUNCTION get_model_ids() CASCADE;
DROP FUNCTION get_posterior_ids() CASCADE;


/* CASCADE drops the associated triggers: */
DROP FUNCTION check_for_references() CASCADE;
DROP FUNCTION forbid_dangling_input_references() CASCADE;
DROP FUNCTION forbid_dangling_model_references() CASCADE;
DROP FUNCTION forbid_dangling_posterior_references() CASCADE;

    }

  end
end
