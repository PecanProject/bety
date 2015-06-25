class FixIdGetters < ActiveRecord::Migration
  def up

    execute %q{

/* CASCADE drops the associated CHECK constraints: */
DROP FUNCTION get_input_ids() CASCADE;
DROP FUNCTION get_model_ids() CASCADE;
DROP FUNCTION get_posterior_ids() CASCADE;

/* dbfiles */

CREATE FUNCTION get_input_ids(
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


CREATE FUNCTION get_model_ids(
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


CREATE FUNCTION get_posterior_ids(
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

/* Re-add the constraints that use these functions: */
ALTER TABLE dbfiles ADD CONSTRAINT valid_input_refs CHECK (container_type != 'Input' OR container_id = ANY(get_input_ids()));
ALTER TABLE dbfiles ADD CONSTRAINT valid_model_refs CHECK (container_type != 'Model' OR container_id = ANY(get_model_ids()));
ALTER TABLE dbfiles ADD CONSTRAINT valid_posterior_refs CHECK (container_type != 'Posterior' OR container_id = ANY(get_posterior_ids()));

    
    }

  end

  def down

    execute %q{

/* CASCADE drops the associated CHECK constraints: */
DROP FUNCTION get_input_ids() CASCADE;
DROP FUNCTION get_model_ids() CASCADE;
DROP FUNCTION get_posterior_ids() CASCADE;

/* dbfiles */

CREATE FUNCTION get_input_ids(
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


CREATE FUNCTION get_model_ids(
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


CREATE FUNCTION get_posterior_ids(
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

/* Re-add the constraints that use these functions: */
ALTER TABLE dbfiles ADD CONSTRAINT valid_input_refs CHECK (container_type != 'Input' OR container_id = ANY(get_input_ids()));
ALTER TABLE dbfiles ADD CONSTRAINT valid_model_refs CHECK (container_type != 'Model' OR container_id = ANY(get_model_ids()));
ALTER TABLE dbfiles ADD CONSTRAINT valid_posterior_refs CHECK (container_type != 'Posterior' OR container_id = ANY(get_posterior_ids()));

    }

  end
end
