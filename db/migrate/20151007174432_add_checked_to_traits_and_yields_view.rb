class AddCheckedToTraitsAndYieldsView < ActiveRecord::Migration
  def self.up
    begin
      execute "DROP VIEW IF EXISTS traits_and_yields_view"
    rescue ActiveRecord::StatementInvalid => e
      down   # Revert this migration and ...
      raise  # ... cancel any later ones.
    end
    begin
      execute %{
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
                          checked >= 0
      }
    rescue ActiveRecord::StatementInvalid => e
      down   # Revert this migration and ...
      raise  # ... cancel any later ones.
    end

  end
  def self.down
    begin
      execute "DROP VIEW IF EXISTS traits_and_yields_view"
    rescue ActiveRecord::StatementInvalid => e
      down   # Revert this migration and ...
      raise  # ... cancel any later ones.
    end
    begin
      execute %{
          CREATE VIEW traits_and_yields_view AS
                  SELECT
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
                          checked > 0
      }
    rescue ActiveRecord::StatementInvalid => e
      down   # Revert this migration and ...
      raise  # ... cancel any later ones.
    end
  end
end
