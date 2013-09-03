class LimitTraitsAndYieldsViewToCheckedData < ActiveRecord::Migration
  def self.up
    begin
      execute "DROP VIEW IF EXISTS traitsview"
      execute %{
          CREATE VIEW traitsview AS
                  SELECT
                          'traits' AS result_type,
                          traits.id AS id,
                          traits.citation_id,
                          traits.site_id,
                          traits.treatment_id,
                          sites.sitename,
                          sites.city,
                          sites.lat,
                          sites.lon,
                          species.scientificname,
                          species.commonname,
                          species.genus,
                          species.id AS species_id,
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
                          traits.notes
                  FROM
                                    traits
                          LEFT JOIN sites ON traits.site_id = sites.id
                          LEFT JOIN species ON traits.specie_id = species.id
                          LEFT JOIN citations ON traits.citation_id = citations.id
                          LEFT JOIN treatments ON traits.treatment_id = treatments.id
                          LEFT JOIN variables ON traits.variable_id = variables.id
                  WHERE traits.checked > 0

      }

      execute "DROP VIEW IF EXISTS yieldsview"
      execute %{
          CREATE VIEW yieldsview AS
                  SELECT
                          'yields' AS result_type,
                          yields.id AS id,
                          yields.citation_id,
                          yields.site_id,
                          yields.treatment_id,
                          sites.sitename,
                          sites.city,
                          sites.lat,
                          sites.lon,
                          species.scientificname,
                          species.commonname,
                          species.genus,
                          species.id AS species_id,
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
                          yields.notes
                          -- mgmtview.planting,
                          -- mgmtview.seeding
                 FROM
                                    yields
                          LEFT JOIN sites ON yields.site_id = sites.id
                          LEFT JOIN species ON yields.specie_id = species.id
                          LEFT JOIN citations ON yields.citation_id = citations.id
                          LEFT JOIN treatments ON yields.treatment_id = treatments.id
                          LEFT JOIN variables ON variables.name = 'Ayield' AND variables.id = 63
                 WHERE yields.checked > 0
      }




      execute "DROP VIEW IF EXISTS traits_and_yields_view"
      execute %{
          CREATE VIEW traits_and_yields_view AS
                  SELECT * FROM traitsview
                      UNION ALL              /* UNION ALL is more efficient and (here) it is equal to UNION */
                  SELECT * FROM yieldsview
      }
    rescue ActiveRecord::StatementInvalid => e
      down   # Revert this migration and ...
      raise  # ... cancel any later ones.
    end
  end

  def self.down
    execute "DROP VIEW IF EXISTS traitsview"
    execute %{
          CREATE VIEW traitsview AS
                  SELECT
                          'traits' AS result_type,
                          traits.id AS id,
                          traits.citation_id,
                          traits.site_id,
                          traits.treatment_id,
                          sites.sitename,
                          sites.city,
                          sites.lat,
                          sites.lon,
                          species.scientificname,
                          species.commonname,
                          species.genus,
                          species.id AS species_id,
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
                          traits.notes
                  FROM
                                    traits
                          LEFT JOIN sites ON traits.site_id = sites.id
                          LEFT JOIN species ON traits.specie_id = species.id
                          LEFT JOIN citations ON traits.citation_id = citations.id
                          LEFT JOIN treatments ON traits.treatment_id = treatments.id
                          LEFT JOIN variables ON traits.variable_id = variables.id

    }

    execute "DROP VIEW IF EXISTS yieldsview"
    execute %{
          CREATE VIEW yieldsview AS
                  SELECT
                          'yields' AS result_type,
                          yields.id AS id,
                          yields.citation_id,
                          yields.site_id,
                          yields.treatment_id,
                          sites.sitename,
                          sites.city,
                          sites.lat,
                          sites.lon,
                          species.scientificname,
                          species.commonname,
                          species.genus,
                          species.id AS species_id,
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
                          yields.notes
                          -- mgmtview.planting,
                          -- mgmtview.seeding
                 FROM
                                    yields
                          LEFT JOIN sites ON yields.site_id = sites.id
                          LEFT JOIN species ON yields.specie_id = species.id
                          LEFT JOIN citations ON yields.citation_id = citations.id
                          LEFT JOIN treatments ON yields.treatment_id = treatments.id
                          LEFT JOIN variables ON variables.name = 'Ayield' AND variables.id = 63
      }




    execute "DROP VIEW IF EXISTS traits_and_yields_view"
    execute %{
        CREATE VIEW traits_and_yields_view AS
                SELECT * FROM traitsview
                    UNION ALL              /* UNION ALL is more efficient and (here) it is equal to UNION */
                SELECT * FROM yieldsview
    }
  end
end
