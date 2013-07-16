class TraitsAndYieldsView < ActiveRecord::Base
  # Passed from controller for validation of ability
#  attr_accessor :current_user
  set_table_name 'traits_and_yields_view'

  # MAYBE SET SCOPE HERE?


  comma do
    #result_type 'result_type'
    #id 'id'
    #citation_id 'citation_id'
    #site_id 'site_id'
    #treatment_id 'treatment_id'
    sitename 'sitename'
    city 'city'

    # sprintf will both round to 2 decimal places and ensure that (e.g.) "14" is displayed as "14.00"
    lat 'lat' do |num| if num.nil? then "[missing]" else sprintf("%0.2f", num.to_f) end end
    lon 'lon' do |num| if num.nil? then "[missing]" else sprintf("%0.2f", num.to_f) end end

    scientificname 'scientificname'
    commonname 'commonname'
    genus 'genus'
    author 'author'
    citation_year 'citation_year'
    treatment 'treatment'
    date 'date'
    month 'month'
    year 'year'
    dateloc 'dateloc'
    trait 'trait'
    mean 'mean' do |num| if num.nil? then "[missing]" else num.to_f.round_to_significant_digit(3) end end
    units 'units'
    n 'n'
    statname 'statname'
    stat 'stat' do |num| if num.nil? then "[missing]" else num.to_f.round_to_significant_digit(3) end end
    notes 'notes'
  end

end
