class AddSitesCultivars < ActiveRecord::Migration
  def up

    execute %q{

CREATE TABLE sites_cultivars (
    id serial8 NOT NULL,
    site_id bigint NOT NULL CONSTRAINT site_exists REFERENCES sites ON UPDATE CASCADE,
    cultivar_id bigint NOT NULL CONSTRAINT cultivar_exists REFERENCES cultivars ON UPDATE CASCADE,
    created_at timestamp(6) without time zone DEFAULT utc_now(),
    updated_at timestamp(6) without time zone DEFAULT utc_now()
);

CREATE OR REPLACE FUNCTION check_correct_cultivar()
  RETURNS TRIGGER AS $$
DECLARE
    required_cultivar_id bigint;
BEGIN
    IF (NEW.site_id IS NOT NULL) THEN
        SELECT cultivar_id FROM sites_cultivars WHERE site_id = NEW.site_id INTO required_cultivar_id;
        IF (required_cultivar_id IS NOT NULL) THEN
            IF (NEW.cultivar_id IS NULL) THEN
                IF (OLD.cultivar_id IS NOT NULL AND OLD.cultivar_id != required_cultivar_id) THEN
                    RAISE NOTICE 'The existing value of cultivar_id is not consistent with the value specified for site_id and no new value of cultivar_id was specified.%', '';
                    RETURN NULL;
                ELSE
                    NEW.cultivar_id = required_cultivar_id;
                END IF;
            ELSIF (NEW.cultivar_id != required_cultivar_id) THEN
                RAISE NOTICE 'The proposed new value of cultivar_id is not consistent with the value specified for site_id.%', '';
                RETURN NULL;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_correct_cultivar_for_site
    BEFORE INSERT OR UPDATE ON traits
    FOR EACH ROW EXECUTE PROCEDURE check_correct_cultivar();




CREATE OR REPLACE FUNCTION set_correct_cultivar()
  RETURNS TRIGGER AS $$
DECLARE
    required_cultivar_id bigint;
BEGIN
    IF (EXISTS(SELECT 1 FROM traits WHERE site_id = NEW.site_id AND cultivar_id != NEW.cultivar_id)) THEN
        RAISE NOTICE 'Some existing traits have cultivar_id values insconsistent with this change.%', '';
        RETURN NULL;
    ELSE
        UPDATE traits SET cultivar_id = NEW.cultivar_id WHERE site_id = NEW.site_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER set_correct_cultivar_for_site
    BEFORE INSERT OR UPDATE ON sites_cultivars
    FOR EACH ROW EXECUTE PROCEDURE set_correct_cultivar();

}
    
  end

  def down
    execute %q{

DROP TRIGGER IF EXISTS set_correct_cultivar_for_site ON sites_cultivars;
DROP FUNCTION IF EXISTS set_correct_cultivar();
DROP TRIGGER IF EXISTS ensure_correct_cultivar_for_site ON traits;
DROP FUNCTION IF EXISTS check_correct_cultivar();
DROP TABLE IF EXISTS sites_cultivars;

  }           
  end
end
