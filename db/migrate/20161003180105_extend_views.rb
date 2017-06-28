class ExtendViews < ActiveRecord::Migration
  def up
    execute "DROP VIEW IF EXISTS traits_and_yields_view"
    execute "DROP VIEW IF EXISTS traits_and_yields_view_private"
    execute "DROP VIEW IF EXISTS yieldsview_private"
    execute "DROP VIEW IF EXISTS traitsview_private"

    execute %q{
 CREATE VIEW traitsview_private AS
        SELECT
                CAST('traits' AS CHAR(6)) AS result_type, -- changed
                traits.id AS id,
                traits.citation_id,
                traits.site_id,
                traits.treatment_id,
                sites.sitename,
                sites.city,
                ST_Y(ST_CENTROID(sites.geometry)) AS lat,
                ST_X(ST_CENTROID(sites.geometry)) AS lon,
                species.scientificname,
                species.commonname,
                species.genus,
                species.id AS species_id,
                traits.cultivar_id,
                citations.author AS author,
                citations.year AS citation_year,
                treatments.name AS treatment,
                traits.date AS raw_date, -- added (renamed)
                site_or_utc_month(traits.date, dateloc, site_id) AS month, -- changed
                site_or_utc_year(traits.date, dateloc, site_id) AS year, -- changed
                pretty_date(date, dateloc, timeloc, site_id) AS date, -- changed and moved
                pretty_time(date, timeloc, site_id) AS time, -- added
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
                users.email,
                cultivars.name AS cultivar, -- added
                entities.name AS entity, -- added
                methods.name AS method -- added
        FROM
                          traits
                LEFT JOIN sites ON traits.site_id = sites.id
                LEFT JOIN species ON traits.specie_id = species.id
                LEFT JOIN citations ON traits.citation_id = citations.id
                LEFT JOIN treatments ON traits.treatment_id = treatments.id
                LEFT JOIN variables ON traits.variable_id = variables.id
                LEFT JOIN users ON traits.user_id = users.id
                LEFT JOIN cultivars ON traits.cultivar_id = cultivars.id
                LEFT JOIN entities ON traits.entity_id = entities.id
                LEFT JOIN methods ON traits.method_id = methods.id;




CREATE VIEW yieldsview_private AS
        SELECT
                CAST('yields' AS CHAR(6)) AS result_type,
                yields.id AS id,
                yields.citation_id,
                yields.site_id,
                yields.treatment_id,
                sites.sitename,
                sites.city,
                ST_Y(ST_CENTROID(sites.geometry)) AS lat,
                ST_X(ST_CENTROID(sites.geometry)) AS lon,
                species.scientificname,
                species.commonname,
                species.genus,
                species.id AS species_id,
                yields.cultivar_id,
                citations.author AS author,
                citations.year AS citation_year,
                treatments.name AS treatment,
                yields.date as raw_date, -- added
                site_or_utc_month(yields.date, dateloc, site_id) AS month, -- changed
                site_or_utc_year(yields.date, dateloc, site_id) AS year, -- changed
                pretty_date(date, dateloc, 9, site_id) AS date, -- changed and moved
                '[time unspecified for yields]'::text AS time, -- added
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
                users.email,
                cultivars.name AS cultivar, -- added
                CAST(NULL AS VARCHAR(255)) AS entity, -- added
                methods.name AS method -- added
       FROM
                          yields
                LEFT JOIN sites ON yields.site_id = sites.id
                LEFT JOIN species ON yields.specie_id = species.id
                LEFT JOIN citations ON yields.citation_id = citations.id
                LEFT JOIN treatments ON yields.treatment_id = treatments.id
                LEFT JOIN variables ON variables.name = 'Ayield'
                LEFT JOIN users ON yields.user_id = users.id
                LEFT JOIN cultivars ON yields.cultivar_id = cultivars.id
                LEFT JOIN methods ON yields.method_id = methods.id;



CREATE VIEW traits_and_yields_view_private AS
        SELECT * FROM traitsview_private
            UNION ALL              /* UNION ALL is more efficient and (here) it is equal to UNION */
        SELECT * FROM yieldsview_private;


CREATE VIEW traits_and_yields_view AS
        SELECT
                checked,
                result_type,
                id,
                citation_id,
                site_id,
                treatment_id,
                sitename,
                city,
                lat,
                lon,
                scientificname,
                commonname,
                genus,
                species_id,
                cultivar_id,
                author,
                citation_year,
                treatment,
                date, -- changed
                time, -- added
                raw_date,
                month,
                year,
                dateloc,
                trait,
                trait_description,
                mean,
                units,
                n,
                statname,
                stat,
                notes,
                access_level,
                cultivar, -- added
                entity, -- added
                method AS method_name -- added
       FROM
                traits_and_yields_view_private
       WHERE
                checked >= 0;
      }


  end

  def down
    execute "DROP VIEW IF EXISTS traits_and_yields_view"
    execute "DROP VIEW IF EXISTS traits_and_yields_view_private"
    execute "DROP VIEW IF EXISTS yieldsview_private"
    execute "DROP VIEW IF EXISTS traitsview_private"

    execute %q{
 CREATE VIEW traitsview_private AS
        SELECT
                CAST('traits' AS CHAR(10)) AS result_type,
                traits.id AS id,
                traits.citation_id,
                traits.site_id,
                traits.treatment_id,
                sites.sitename,
                sites.city,
                ST_Y(ST_CENTROID(sites.geometry)) AS lat,
                ST_X(ST_CENTROID(sites.geometry)) AS lon,
                species.scientificname,
                species.commonname,
                species.genus,
                species.id AS species_id,
                traits.cultivar_id,
                citations.author AS author,
                citations.year AS citation_year,
                treatments.name AS treatment,
                traits.date,
                extract(month from traits.date) AS month,
                extract(year from traits.date) AS year,
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
        FROM
                          traits
                LEFT JOIN sites ON traits.site_id = sites.id
                LEFT JOIN species ON traits.specie_id = species.id
                LEFT JOIN citations ON traits.citation_id = citations.id
                LEFT JOIN treatments ON traits.treatment_id = treatments.id
                LEFT JOIN variables ON traits.variable_id = variables.id
                LEFT JOIN users ON traits.user_id = users.id;




CREATE VIEW yieldsview_private AS
        SELECT
                CAST('yields' AS CHAR(10)) AS result_type,
                yields.id AS id,
                yields.citation_id,
                yields.site_id,
                yields.treatment_id,
                sites.sitename,
                sites.city,
                ST_Y(ST_CENTROID(sites.geometry)) AS lat,
                ST_X(ST_CENTROID(sites.geometry)) AS lon,
                species.scientificname,
                species.commonname,
                species.genus,
                species.id AS species_id,
                yields.cultivar_id,
                citations.author AS author,
                citations.year AS citation_year,
                treatments.name AS treatment,
                yields.date,
                extract(month from yields.date) AS month,
                extract(year from yields.date) AS year,
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
       FROM
                          yields
                LEFT JOIN sites ON yields.site_id = sites.id
                LEFT JOIN species ON yields.specie_id = species.id
                LEFT JOIN citations ON yields.citation_id = citations.id
                LEFT JOIN treatments ON yields.treatment_id = treatments.id
                LEFT JOIN variables ON variables.name = 'Ayield'
                LEFT JOIN users ON yields.user_id = users.id;



CREATE VIEW traits_and_yields_view_private AS
        SELECT * FROM traitsview_private
            UNION ALL              /* UNION ALL is more efficient and (here) it is equal to UNION */
        SELECT * FROM yieldsview_private;


CREATE VIEW traits_and_yields_view AS
        SELECT
                checked,
                result_type,
                id,
                citation_id,
                site_id,
                treatment_id,
                sitename,
                city,
                lat,
                lon,
                scientificname,
                commonname,
                genus,
                species_id,
                cultivar_id,
                author,
                citation_year,
                treatment,
                date,
                month,
                year,
                dateloc,
                trait,
                trait_description,
                mean,
                units,
                n,
                statname,
                stat,
                notes,
                access_level
       FROM
                traits_and_yields_view_private
       WHERE
                checked >= 0;
      }


  end
end
