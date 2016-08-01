class AddTraitAndYieldDateAndTimeFunctions < ActiveRecord::Migration
  def up

    # Use "%q" so that backspashes are taken literally (except when doubled).
    execute %q{

CREATE OR REPLACE FUNCTION pretty_date(
    date timestamp,
    dateloc numeric(4,2),
    timeloc numeric(4,2),
    site_id bigint
) RETURNS text AS $body$
DECLARE
    FORMAT text;
    SEASON text;
    SITE_OR_UTC_TIMEZONE text;
    TIMEZONE_DESIGNATION text;
    SITE_OR_UTC_DATE timestamp;
BEGIN

    IF site_id IS NULL THEN
        SITE_OR_UTC_TIMEZONE := 'UTC';
    ELSE
        SELECT COALESCE(time_zone, 'UTC') FROM sites WHERE id = site_id INTO SITE_OR_UTC_TIMEZONE;
    END IF;

    TIMEZONE_DESIGNATION := '';
    IF timeloc = 9 AND dateloc IN (5, 6, 8, 95, 96) THEN
        TIMEZONE_DESIGNATION := FORMAT(' (%s)', SITE_OR_UTC_TIMEZONE);
    END IF;

    /* Interpret the date column as being UTC (not server time!), then convert it site time (if determined) or UTC.
       Note that "date || ' UTC'" is NULL if date is NULL (unlike CONCAT(date, ' UTC'), which is ' UTC' if date is NULL).
       This is what we want. */
    SELECT CAST((date::text || ' UTC') AS timestamp with time zone) AT TIME ZONE SITE_OR_UTC_TIMEZONE INTO SITE_OR_UTC_DATE;

    CASE extract(month FROM SITE_OR_UTC_DATE)
        WHEN 1 THEN
            SEASON := '"DJF"';
        WHEN 4 THEN
            SEASON := '"MAM"';
        WHEN 7 THEN
            SEASON := '"JJA"';
        WHEN 10 THEN
            SEASON := '"SON"';
        ELSE
            SEASON := '"[UNRECOGNIZED SEASON MONTH]"';
    END CASE;


    CASE COALESCE(dateloc, -1)

        WHEN 9 THEN
            FORMAT := '"[date unspecified or unknown]"';

        WHEN 8 THEN
            FORMAT := 'YYYY';

        WHEN 7 THEN                   
            FORMAT := CONCAT('Season: ', SEASON, ' YYYY');

        WHEN 6 THEN
            FORMAT := 'FMMonth YYYY';

        WHEN 5.5 THEN
            FORMAT := '"Week of" Mon FMDD, YYYY';

        WHEN 5 THEN
            FORMAT := 'YYYY Mon FMDD';

        WHEN 97 THEN
            FORMAT := CONCAT('Season: ', SEASON);

        WHEN 96 THEN
            FORMAT := 'FMMonth';

        WHEN 95 THEN
            FORMAT := 'FMMonth FMDDth';

        WHEN -1 THEN
            FORMAT := '"Date Level of Confidence Unknown"';

        ELSE
            FORMAT := '"Unrecognized Value for Date Level of Confidence"';
    END CASE;

    RETURN CONCAT(to_char(SITE_OR_UTC_DATE, FORMAT), TIMEZONE_DESIGNATION);

END;
$body$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION pretty_time(
    date timestamp,
    timeloc numeric(4,2),
    site_id bigint
) RETURNS text AS $body$
DECLARE
    FORMAT text;
    TIME_OF_DAY text;
    SITE_OR_UTC_TIMEZONE text;
    TIMEZONE_DESIGNATION text;
    SITE_OR_UTC_DATE timestamp;
BEGIN


    IF site_id IS NULL THEN
        SITE_OR_UTC_TIMEZONE := 'UTC';
    ELSE
        SELECT COALESCE(time_zone, 'UTC') FROM sites WHERE id = site_id INTO SITE_OR_UTC_TIMEZONE;
    END IF;

    TIMEZONE_DESIGNATION := '';
    IF timeloc != 9 THEN
        TIMEZONE_DESIGNATION := FORMAT(' (%s)', SITE_OR_UTC_TIMEZONE);
    END IF;

    /* Interpret the date column as being UTC (not server time!), then convert it site time (if determined) or UTC.
       Note that "date || ' UTC'" is NULL if date is NULL (unlike CONCAT(date, ' UTC)', which is ' UTC' if date is NULL.
       This is what we want. */
    SELECT CAST((date::text || ' UTC') AS timestamp with time zone) AT TIME ZONE SITE_OR_UTC_TIMEZONE INTO SITE_OR_UTC_DATE;


    CASE extract(hour FROM SITE_OR_UTC_DATE)
        WHEN 0 THEN
            TIME_OF_DAY := '"night"';
        WHEN 9 THEN
            TIME_OF_DAY := '"morning"';
        WHEN 12 THEN
            TIME_OF_DAY := '"mid-day"';
        WHEN 15 THEN
            TIME_OF_DAY := '"afternoon"';
        ELSE
            TIME_OF_DAY := '"[Invalid time-of-day designation]"';
    END CASE;


    CASE COALESCE(timeloc, -1)


        WHEN 9 THEN
            FORMAT := '"[time unspecified or unknown]"';

        WHEN 4 THEN
            FORMAT := TIME_OF_DAY;

        WHEN 3 THEN
            FORMAT := 'FMHH AM';

        WHEN 2 THEN
            FORMAT := 'HH24:MI';

        WHEN 1 THEN
            FORMAT := 'HH24:MI:SS';

        WHEN -1 THEN
            FORMAT := '"Time Level of Confidence Unknown"';

        ELSE
            FORMAT := '"Unrecognized Value for Time Level of Confidence"';

    END CASE;

    RETURN CONCAT(to_char(SITE_OR_UTC_DATE, FORMAT), TIMEZONE_DESIGNATION);

END;
$body$ LANGUAGE plpgsql;




    }

  end

  def down

    execute %q{

DROP FUNCTION pretty_date(
    date timestamp,
    dateloc numeric(4,2),
    timeloc numeric(4,2),
    site_id bigint
);

DROP FUNCTION pretty_time(
    date timestamp,
    timeloc numeric(4,2),
    site_id bigint
)

    }

  end
end
