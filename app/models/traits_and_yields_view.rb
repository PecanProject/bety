class TraitsAndYieldsView < ActiveRecord::Base
  # Passed from controller for validation of ability
#  attr_accessor :current_user
  set_table_name 'traits_and_yields_view'

  extend AdvancedSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ traits_and_yields_view.scientificname traits_and_yields_view.commonname 
                      traits_and_yields_view.trait traits_and_yields_view.trait_description
                      traits_and_yields_view.city traits_and_yields_view.sitename }

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(advanced_search(search)) }

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
    lat 'lat' do |num| num = num.nil? ? '[missing]' : sprintf("%0.2f", num) end
    lon 'lon' do |num| num = num.nil? ? '[missing]' : sprintf("%0.2f", num) end

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
