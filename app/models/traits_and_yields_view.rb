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
  scope :restrict_access, lambda { |access_level| where("access_level >= #{access_level}")  }

  # MAYBE SET SCOPE HERE?

  # make NumberHelper available to use inside comma block:
  extend ActionView::Helpers::NumberHelper

  comma do
    #result_type 'result_type'
    #id 'id'
    #citation_id 'citation_id'
    #site_id 'site_id'
    #treatment_id 'treatment_id'
    sitename 'sitename'
    city 'city'
    lat 'lat' do |num|
      num.nil? ? '[missing]' : TraitsAndYieldsView.number_with_precision(num, precision: 2)
    end
    lon 'lon' do |num|
      num.nil? ? '[missing]' : TraitsAndYieldsView.number_with_precision(num, precision: 2)
    end
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
    mean 'mean' do |num|
      if num.nil? then
        "[missing]"
      else
        TraitsAndYieldsView.number_with_precision(num, precision: 3, significant: true)
      end
    end
    units 'units'
    n 'n'
    statname 'statname'
    stat 'stat' do |num|
      if num.nil? then
        "[missing]"
      else 
        TraitsAndYieldsView.number_with_precision(num, precision: 3)#, significant: true)
      end 
    end
    notes 'notes'
  end

end
