class TraitsAndYieldsView < ActiveRecord::Base
  # Passed from controller for validation of ability
#  attr_accessor :current_user
  set_table_name 'traits_and_yields_view'

  # MAYBE SET SCOPE HERE?


  comma do
    result_type
    id
    citation_id
    site_id
    treatment_id
    sitename
    city
    lat
    lon
    scientificname
    commonname
    genus
    author
    citation_year
    treatment
    date
    month
    year
    dateloc
    trait
    mean
    units
    n
    statname
    stat
    notes
    user_name
  end

end
