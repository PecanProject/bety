class ChangeIdToBigInt < ActiveRecord::Migration
  def self.up
    begin
        execute "DROP VIEW IF EXISTS traits_and_yields_view"
        execute "DROP VIEW IF EXISTS yieldsview"
        execute "DROP VIEW IF EXISTS traitsview"
    rescue ActiveRecord::StatementInvalid => e
        down   # Revert this migration and ...
        raise  # ... cancel any later ones.
    end

    change_column :citations, :id, :integer, :limit => 8
    change_column :citations, :user_id, :integer, :limit => 8

    change_column :citations_sites, :citation_id, :integer, :limit => 8
    change_column :citations_sites, :site_id, :integer, :limit => 8

    change_column :citations_treatments, :citation_id, :integer, :limit => 8
    change_column :citations_treatments, :treatment_id, :integer, :limit => 8

    change_column :counties, :id, :integer, :limit => 8

    change_column :covariates, :id, :integer, :limit => 8
    change_column :covariates, :trait_id, :integer, :limit => 8
    change_column :covariates, :variable_id, :integer, :limit => 8
    
    change_column :cultivars, :id, :integer, :limit => 8
    change_column :cultivars, :specie_id, :integer, :limit => 8

    change_column :dbfiles, :id, :integer, :limit => 8
    change_column :dbfiles, :created_user_id, :integer, :limit => 8
    change_column :dbfiles, :updated_user_id, :integer, :limit => 8
    change_column :dbfiles, :machine_id, :integer, :limit => 8
    change_column :dbfiles, :container_id, :integer, :limit => 8

    change_column :ensembles, :id, :integer, :limit => 8
    change_column :ensembles, :workflow_id, :integer, :limit => 8

    change_column :entities, :id, :integer, :limit => 8
    change_column :entities, :parent_id, :integer, :limit => 8

    change_column :formats, :id, :integer, :limit => 8

    change_column :formats_variables, :id, :integer, :limit => 8
    change_column :formats_variables, :format_id, :integer, :limit => 8
    change_column :formats_variables, :variable_id, :integer, :limit => 8

    change_column :inputs, :id, :integer, :limit => 8
    change_column :inputs, :site_id, :integer, :limit => 8
    change_column :inputs, :parent_id, :integer, :limit => 8
    change_column :inputs, :user_id, :integer, :limit => 8
    change_column :inputs, :format_id, :integer, :limit => 8

    change_column :inputs_runs, :input_id, :integer, :limit => 8
    change_column :inputs_runs, :run_id, :integer, :limit => 8

    change_column :inputs_variables, :input_id, :integer, :limit => 8
    change_column :inputs_variables, :variable_id, :integer, :limit => 8

    change_column :likelihoods, :id, :integer, :limit => 8
    change_column :likelihoods, :run_id, :integer, :limit => 8
    change_column :likelihoods, :variable_id, :integer, :limit => 8
    change_column :likelihoods, :input_id, :integer, :limit => 8

    change_column :location_yields, :id, :integer, :limit => 8
    change_column :location_yields, :county_id, :integer, :limit => 8

    change_column :machines, :id, :integer, :limit => 8

    change_column :managements, :id, :integer, :limit => 8
    change_column :managements, :citation_id, :integer, :limit => 8
    change_column :managements, :user_id, :integer, :limit => 8

    change_column :managements_treatments, :treatment_id, :integer, :limit => 8
    change_column :managements_treatments, :management_id, :integer, :limit => 8

    change_column :methods, :id, :integer, :limit => 8
    change_column :methods, :citation_id, :integer, :limit => 8

    change_column :mimetypes, :id, :integer, :limit => 8

    change_column :models, :id, :integer, :limit => 8
    change_column :models, :parent_id, :integer, :limit => 8

    change_column :pfts, :id, :integer, :limit => 8
    change_column :pfts, :parent_id, :integer, :limit => 8

    change_column :pfts_priors, :pft_id, :integer, :limit => 8
    change_column :pfts_priors, :prior_id, :integer, :limit => 8

    change_column :pfts_species, :pft_id, :integer, :limit => 8
    change_column :pfts_species, :specie_id, :integer, :limit => 8

    change_column :posteriors, :id, :integer, :limit => 8
    change_column :posteriors, :pft_id, :integer, :limit => 8
    change_column :posteriors, :format_id, :integer, :limit => 8

    change_column :posteriors_runs, :posterior_id, :integer, :limit => 8
    change_column :posteriors_runs, :run_id, :integer, :limit => 8

    change_column :priors, :id, :integer, :limit => 8
    change_column :priors, :citation_id, :integer, :limit => 8
    change_column :priors, :variable_id, :integer, :limit => 8

    change_column :runs, :id, :integer, :limit => 8
    change_column :runs, :model_id, :integer, :limit => 8
    change_column :runs, :site_id, :integer, :limit => 8
    change_column :runs, :ensemble_id, :integer, :limit => 8

    change_column :sessions, :id, :integer, :limit => 8

    change_column :sites, :id, :integer, :limit => 8
    change_column :sites, :user_id, :integer, :limit => 8

    change_column :species, :id, :integer, :limit => 8

    change_column :traits, :id, :integer, :limit => 8
    change_column :traits, :site_id, :integer, :limit => 8
    change_column :traits, :specie_id, :integer, :limit => 8
    change_column :traits, :citation_id, :integer, :limit => 8
    change_column :traits, :cultivar_id, :integer, :limit => 8
    change_column :traits, :treatment_id, :integer, :limit => 8
    change_column :traits, :variable_id, :integer, :limit => 8
    change_column :traits, :user_id, :integer, :limit => 8
    change_column :traits, :entity_id, :integer, :limit => 8
    change_column :traits, :method_id, :integer, :limit => 8

    change_column :treatments, :id, :integer, :limit => 8
    change_column :treatments, :user_id, :integer, :limit => 8

    change_column :users, :id, :integer, :limit => 8

    change_column :variables, :id, :integer, :limit => 8

    change_column :workflows, :id, :integer, :limit => 8
    change_column :workflows, :site_id, :integer, :limit => 8
    change_column :workflows, :model_id, :integer, :limit => 8

    change_column :yields, :id, :integer, :limit => 8
    change_column :yields, :citation_id, :integer, :limit => 8
    change_column :yields, :site_id, :integer, :limit => 8
    change_column :yields, :specie_id, :integer, :limit => 8
    change_column :yields, :treatment_id, :integer, :limit => 8
    change_column :yields, :cultivar_id, :integer, :limit => 8
    change_column :yields, :user_id, :integer, :limit => 8
    change_column :yields, :method_id, :integer, :limit => 8

     begin
      execute %{
          CREATE VIEW traitsview AS
                  SELECT
                          CAST('traits' AS CHAR(10)) AS result_type,
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
                          traits.notes,
                          traits.access_level
                  FROM
                                    traits
                          LEFT JOIN sites ON traits.site_id = sites.id
                          LEFT JOIN species ON traits.specie_id = species.id
                          LEFT JOIN citations ON traits.citation_id = citations.id
                          LEFT JOIN treatments ON traits.treatment_id = treatments.id
                          LEFT JOIN variables ON traits.variable_id = variables.id
                  WHERE traits.checked > 0;

      }

      execute %{
          CREATE VIEW yieldsview AS
                  SELECT
                          CAST('yields' AS CHAR(10)) AS result_type,
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
                          yields.notes,
                          yields.access_level
                 FROM
                                    yields
                          LEFT JOIN sites ON yields.site_id = sites.id
                          LEFT JOIN species ON yields.specie_id = species.id
                          LEFT JOIN citations ON yields.citation_id = citations.id
                          LEFT JOIN treatments ON yields.treatment_id = treatments.id
                          LEFT JOIN variables ON variables.name = 'Ayield' AND variables.id = 63
                 WHERE yields.checked > 0
      }

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
    execute "DROP VIEW IF EXISTS traits_and_yields_view"
    execute "DROP VIEW IF EXISTS yieldsview"
    execute "DROP VIEW IF EXISTS traitsview"

    change_column :citations, :id, :integer, :limit => 4
    change_column :citations, :user_id, :integer, :limit => 4

    change_column :citations_sites, :citation_id, :integer, :limit => 4
    change_column :citations_sites, :site_id, :integer, :limit => 4

    change_column :citations_treatments, :citation_id, :integer, :limit => 4
    change_column :citations_treatments, :treatment_id, :integer, :limit => 4

    change_column :counties, :id, :integer, :limit => 4

    change_column :covariates, :id, :integer, :limit => 4
    change_column :covariates, :trait_id, :integer, :limit => 4
    change_column :covariates, :variable_id, :integer, :limit => 4
    
    change_column :cultivars, :id, :integer, :limit => 4
    change_column :cultivars, :specie_id, :integer, :limit => 4

    change_column :dbfiles, :id, :integer, :limit => 4
    change_column :dbfiles, :created_user_id, :integer, :limit => 4
    change_column :dbfiles, :updated_user_id, :integer, :limit => 4
    change_column :dbfiles, :machine_id, :integer, :limit => 4
    change_column :dbfiles, :container_id, :integer, :limit => 4

    change_column :ensembles, :id, :integer, :limit => 4
    change_column :ensembles, :workflow_id, :integer, :limit => 4

    change_column :entities, :id, :integer, :limit => 4
    change_column :entities, :parent_id, :integer, :limit => 4

    change_column :formats, :id, :integer, :limit => 4

    change_column :formats_variables, :id, :integer, :limit => 4
    change_column :formats_variables, :format_id, :integer, :limit => 4
    change_column :formats_variables, :variable_id, :integer, :limit => 4

    change_column :inputs, :id, :integer, :limit => 4
    change_column :inputs, :site_id, :integer, :limit => 4
    change_column :inputs, :parent_id, :integer, :limit => 4
    change_column :inputs, :user_id, :integer, :limit => 4
    change_column :inputs, :format_id, :integer, :limit => 4

    change_column :inputs_runs, :input_id, :integer, :limit => 4
    change_column :inputs_runs, :run_id, :integer, :limit => 4

    change_column :inputs_variables, :input_id, :integer, :limit => 4
    change_column :inputs_variables, :variable_id, :integer, :limit => 4

    change_column :likelihoods, :id, :integer, :limit => 4
    change_column :likelihoods, :run_id, :integer, :limit => 4
    change_column :likelihoods, :variable_id, :integer, :limit => 4
    change_column :likelihoods, :input_id, :integer, :limit => 4

    change_column :location_yields, :id, :integer, :limit => 4
    change_column :location_yields, :county_id, :integer, :limit => 4

    change_column :machines, :id, :integer, :limit => 4

    change_column :managements, :id, :integer, :limit => 4
    change_column :managements, :citation_id, :integer, :limit => 4
    change_column :managements, :user_id, :integer, :limit => 4

    change_column :managements_treatments, :treatment_id, :integer, :limit => 4
    change_column :managements_treatments, :management_id, :integer, :limit => 4

    change_column :methods, :id, :integer, :limit => 4
    change_column :methods, :citation_id, :integer, :limit => 4

    change_column :mimetypes, :id, :integer, :limit => 4

    change_column :models, :id, :integer, :limit => 4
    change_column :models, :parent_id, :integer, :limit => 4

    change_column :pfts, :id, :integer, :limit => 4
    change_column :pfts, :parent_id, :integer, :limit => 4

    change_column :pfts_priors, :pft_id, :integer, :limit => 4
    change_column :pfts_priors, :prior_id, :integer, :limit => 4

    change_column :pfts_species, :pft_id, :integer, :limit => 4
    change_column :pfts_species, :specie_id, :integer, :limit => 4

    change_column :posteriors, :id, :integer, :limit => 4
    change_column :posteriors, :pft_id, :integer, :limit => 4
    change_column :posteriors, :format_id, :integer, :limit => 4

    change_column :posteriors_runs, :posterior_id, :integer, :limit => 4
    change_column :posteriors_runs, :run_id, :integer, :limit => 4

    change_column :priors, :id, :integer, :limit => 4
    change_column :priors, :citation_id, :integer, :limit => 4
    change_column :priors, :variable_id, :integer, :limit => 4

    change_column :runs, :id, :integer, :limit => 4
    change_column :runs, :model_id, :integer, :limit => 4
    change_column :runs, :site_id, :integer, :limit => 4
    change_column :runs, :ensemble_id, :integer, :limit => 4

    change_column :sessions, :id, :integer, :limit => 4

    change_column :sites, :id, :integer, :limit => 4
    change_column :sites, :user_id, :integer, :limit => 4

    change_column :species, :id, :integer, :limit => 4

    change_column :traits, :id, :integer, :limit => 4
    change_column :traits, :site_id, :integer, :limit => 4
    change_column :traits, :specie_id, :integer, :limit => 4
    change_column :traits, :citation_id, :integer, :limit => 4
    change_column :traits, :cultivar_id, :integer, :limit => 4
    change_column :traits, :treatment_id, :integer, :limit => 4
    change_column :traits, :variable_id, :integer, :limit => 4
    change_column :traits, :user_id, :integer, :limit => 4
    change_column :traits, :entity_id, :integer, :limit => 4
    change_column :traits, :method_id, :integer, :limit => 4

    change_column :treatments, :id, :integer, :limit => 4
    change_column :treatments, :user_id, :integer, :limit => 4

    change_column :users, :id, :integer, :limit => 4

    change_column :variables, :id, :integer, :limit => 4

    change_column :workflows, :id, :integer, :limit => 4
    change_column :workflows, :site_id, :integer, :limit => 4
    change_column :workflows, :model_id, :integer, :limit => 4

    change_column :yields, :id, :integer, :limit => 4
    change_column :yields, :citation_id, :integer, :limit => 4
    change_column :yields, :site_id, :integer, :limit => 4
    change_column :yields, :specie_id, :integer, :limit => 4
    change_column :yields, :treatment_id, :integer, :limit => 4
    change_column :yields, :cultivar_id, :integer, :limit => 4
    change_column :yields, :user_id, :integer, :limit => 4
    change_column :yields, :method_id, :integer, :limit => 4

    execute %{
          CREATE VIEW traitsview AS
                  SELECT
                          CAST('traits' AS CHAR(10)) AS result_type,
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
                          traits.notes,
                          traits.access_level
                  FROM
                                    traits
                          LEFT JOIN sites ON traits.site_id = sites.id
                          LEFT JOIN species ON traits.specie_id = species.id
                          LEFT JOIN citations ON traits.citation_id = citations.id
                          LEFT JOIN treatments ON traits.treatment_id = treatments.id
                          LEFT JOIN variables ON traits.variable_id = variables.id
                  WHERE traits.checked > 0;

      }

      execute %{
          CREATE VIEW yieldsview AS
                  SELECT
                          CAST('yields' AS CHAR(10)) AS result_type,
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
                          yields.notes,
                          yields.access_level
                 FROM
                                    yields
                          LEFT JOIN sites ON yields.site_id = sites.id
                          LEFT JOIN species ON yields.specie_id = species.id
                          LEFT JOIN citations ON yields.citation_id = citations.id
                          LEFT JOIN treatments ON yields.treatment_id = treatments.id
                          LEFT JOIN variables ON variables.name = 'Ayield' AND variables.id = 63
                 WHERE yields.checked > 0
      }

      execute %{
          CREATE VIEW traits_and_yields_view AS
                  SELECT * FROM traitsview
                      UNION ALL              /* UNION ALL is more efficient and (here) it is equal to UNION */
                  SELECT * FROM yieldsview
      }
  end
end

