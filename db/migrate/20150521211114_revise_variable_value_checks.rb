class ReviseVariableValueChecks < ActiveRecord::Migration
  def up
    execute %{

/* Trigger function to ensure that updates to the min or max values in
   the variables table do not cause any existing trait or covariate
   values to be out of range.
*/
CREATE OR REPLACE FUNCTION prevent_conflicting_range_changes() RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prevent_conflicting_range_changes ON variables;
CREATE TRIGGER prevent_conflicting_range_changes
  BEFORE UPDATE OF min, max ON variables
  FOR EACH ROW
EXECUTE PROCEDURE prevent_conflicting_range_changes();

COMMENT ON TRIGGER prevent_conflicting_range_changes ON variables IS
  'Trigger function to ensure that updates to the min or max values in
   the variables table do not cause any existing trait or covariate
   values to be out of range.';

    }
  end

  def down
    execute %{

/* Trigger function to ensure that updates to the min or max values in
   the variables table do not cause any existing trait or covariate
   values to be out of range.
*/
CREATE OR REPLACE FUNCTION prevent_conflicting_range_changes() RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prevent_conflicting_range_changes ON variables;
CREATE TRIGGER prevent_conflicting_range_changes
  BEFORE UPDATE ON variables
  FOR EACH ROW
EXECUTE PROCEDURE prevent_conflicting_range_changes();

COMMENT ON TRIGGER prevent_conflicting_range_changes ON variables IS
  'Trigger function to ensure that updates to the min or max values in
   the variables table do not cause any existing trait or covariate
   values to be out of range.';

    }
  end
end
