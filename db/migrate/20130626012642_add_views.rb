class CreateMyView < ActiveRecord::Migration
  def self.up
    execute <<-SQL
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
              citations.author AS author,
              citations.year AS citation_year,
              treatments.name AS treatment,
              traits.date,
              month(traits.date) AS month,
              year(traits.date) AS year,
              traits.dateloc,
              variables.name AS trait,
              traits.mean,
              variables.units,
              traits.n,
              traits.statname,
              traits.stat,
              traits.notes,
              users.name AS user_name

              
       FROM
                 traits
            LEFT JOIN sites ON traits.site_id = sites.id
            LEFT JOIN species ON traits.specie_id = species.id
            LEFT JOIN citations ON traits.citation_id = citations.id
            LEFT JOIN treatments ON traits.treatment_id = treatments.id
            LEFT JOIN variables ON traits.variable_id = variables.id
            LEFT JOIN users ON traits.user_id = users.id;
    SQL
  end
  def self.down
    execute <<-SQL
      DROP VIEW traitsview
    SQL
  end
end
class CreateMyView < ActiveRecord::Migration
  def self.up
    execute <<-SQL
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
              citations.author AS author,
              citations.year AS citation_year,
              treatments.name AS treatment,
              yields.date,
              month(yields.date) AS month,
              year(yields.date) AS year,
              yields.dateloc,
              variables.name AS trait,
              yields.mean,
              variables.units,
              yields.n,
              yields.statname,
              yields.stat,
              yields.notes,
              users.name AS user_name
              -- mgmtview.planting,
              -- mgmtview.seeding
       FROM
                   yields
              LEFT JOIN sites ON yields.site_id = sites.id
              LEFT JOIN species ON yields.specie_id = species.id
              LEFT JOIN citations ON yields.citation_id = citations.id
              LEFT JOIN treatments ON yields.treatment_id = treatments.id
              LEFT JOIN variables ON variables.name = 'Ayield' AND variables.id = 63
              LEFT JOIN users ON yields.user_id = users.id
  end
  def self.down
    execute <<-SQL
      DROP VIEW yieldsview
    SQL
  end
end

class CreateMyView < ActiveRecord::Migration
  def self.up
    execute <<-SQL
CREATE VIEW traits_and_yields_view AS
       SELECT * FROM traitsview
           UNION ALL /* UNION ALL more efficient and (here) equal to UNION */
       SELECT * FROM yieldsview;
    SQL
  end
  def self.down
    execute <<-SQL
      DROP VIEW traits_and_yields_view;
    SQL
  end
end
