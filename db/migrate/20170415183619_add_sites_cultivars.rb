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
  RETURNS TRIGGER AS  $body$
DECLARE
    required_cultivar_id bigint;
    required_specie_id bigint;
BEGIN
    SELECT cultivar_id FROM sites_cultivars WHERE site_id = NEW.site_id INTO required_cultivar_id;
    IF (required_cultivar_id IS NOT NULL) THEN
        SELECT specie_id FROM cultivars WHERE id = required_cultivar_id INTO required_specie_id;
    ELSE
        SELECT specie_id FROM cultivars WHERE id = NEW.cultivar_id INTO required_specie_id;
    END IF;
    IF (required_cultivar_id IS NULL) THEN
        IF (NEW.cultivar_id IS NULL) THEN
            NULL;
        ELSIF (NEW.specie_id IS NULL) THEN
            NEW.specie_id := required_specie_id;
        ELSIF (NEW.specie = required_specie_id) THEN
            NULL;
        ELSE
            RAISE NOTICE 'The species id % is not consistent with the cultivar id %.', NEW.specie_id, NEW.cultivar_id;
            RETURN NULL;
        END IF;
    ELSE
        IF (NEW.cultivar_id IS NULL) THEN
            IF (NEW.specie_id IS NULL) THEN
                NEW.cultivar_id := required_cultivar_id;
                NEW.specie_id := required_specie_id;
            ELSIF (NEW.specie_id = required_specie_id) THEN
                NEW.cultivar_id := required_cultivar_id;
            ELSE
                RAISE NOTICE 'The species id % is not consistent with the cultivar id %.  It should be %.', NEW.specie_id, required_cultivar_id, required_specie_id;
                RETURN NULL;
            END IF;
        ELSIF (NEW.cultivar_id = required_cultivar_id) THEN
            IF (NEW.specie_id IS NULL) THEN
                NEW.specie_id := required_specie_id;
            ELSIF (NEW.specie_id != required_specie_id) THEN
                RAISE NOTICE 'The species id % is not consistent with the cultivar id %.  It should be %.', NEW.specie_id, NEW.cultivar_id, required_specie_id;
                RETURN NULL;
            END IF;
        ELSE
            RAISE NOTICE 'The value of cultivar_id (%) is not consistent with the value % specified for site_id %.', NEW.cultivar_id, required_cultivar_id, NEW.site_id;
            RETURN NULL;
        END IF;
    END IF;
    RETURN NEW;
END;
$body$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ensure_correct_cultivar_for_site ON traits;
CREATE TRIGGER ensure_correct_cultivar_for_site
    BEFORE INSERT OR UPDATE OF site_id, cultivar_id, specie_id ON traits
    FOR EACH ROW EXECUTE PROCEDURE check_correct_cultivar();




CREATE OR REPLACE FUNCTION set_correct_cultivar()
  RETURNS TRIGGER AS $body$
DECLARE
    required_cultivar_id bigint;
BEGIN
    IF (EXISTS(SELECT 1 FROM traits WHERE site_id = NEW.site_id AND cultivar_id != NEW.cultivar_id)) THEN
        RAISE NOTICE 'Some existing traits have cultivar_id values inconsistent with this change.%', '';
        RETURN NULL;
    ELSE
        UPDATE traits SET cultivar_id = NEW.cultivar_id WHERE site_id = NEW.site_id;
    END IF;
    RETURN NEW;
END;
$body$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS set_correct_cultivar_for_site ON sites_cultivars;
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
