class AddTriggersToCheckVariableRanges < ActiveRecord::Migration
  def self.up
    execute %{

/* Trigger function to ensure values of mean in the traits table are
   within the range specified by min and max in the variables table.
   A NULL in the min or max column means "no limit".
*/
CREATE OR REPLACE FUNCTION restrict_trait_range() RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS restrict_trait_range ON traits;
CREATE TRIGGER restrict_trait_range
  BEFORE INSERT OR UPDATE ON traits 
  FOR EACH ROW 
EXECUTE PROCEDURE restrict_trait_range();

COMMENT ON TRIGGER restrict_trait_range ON traits IS
   'Trigger function to ensure values of mean in the traits table are
   within the range specified by min and max in the variables table.
   A NULL in the min or max column means "no limit".';


/* Trigger function to ensure values of level in the covariates table
   are within the range specified by min and max in the variables
   table.  A NULL in the min or max column means "no limit".
*/
CREATE OR REPLACE FUNCTION restrict_covariate_range() RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS restrict_covariate_range ON covariates;
CREATE TRIGGER restrict_covariate_range
  BEFORE INSERT OR UPDATE ON covariates 
  FOR EACH ROW 
EXECUTE PROCEDURE restrict_covariate_range();

COMMENT ON TRIGGER restrict_covariate_range ON covariates IS
  'Trigger function to ensure values of level in the covariates table
   are within the range specified by min and max in the variables
   table.  A NULL in the min or max column means "no limit".';


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
  BEFORE INSERT OR UPDATE ON variables 
  FOR EACH ROW 
EXECUTE PROCEDURE prevent_conflicting_range_changes();

COMMENT ON TRIGGER prevent_conflicting_range_changes ON variables IS
  'Trigger function to ensure that updates to the min or max values in
   the variables table do not cause any existing trait or covariate
   values to be out of range.';

    }    
  end

  def self.down
    execute %{

DROP TRIGGER IF EXISTS restrict_trait_range ON traits;
DROP FUNCTION IF EXISTS restrict_trait_range();

DROP TRIGGER IF EXISTS restrict_covariate_range ON covariates;
DROP FUNCTION IF EXISTS restrict_covariate_range();

DROP TRIGGER IF EXISTS prevent_conflicting_range_changes ON variables;
DROP FUNCTION IF EXISTS prevent_conflicting_range_changes();

}
  end
end

