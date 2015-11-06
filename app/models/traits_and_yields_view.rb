# This overrides the to_comma method in the "comma" gem, replacing the
# iterator_method parameter value passed to the Comma::Generator#run
# method so that it uses "find_all" instead of "find_each".
# ("find_each" doesn't seem to work correctly with SQL views in rails
# 3.0.8.)
class ActiveRecord::Relation
  def to_comma(style = :default)
    Comma::Generator.new(self, style).run(:find_all)
  end
end

class TraitsAndYieldsView < ActiveRecord::Base
  # Passed from controller for validation of ability
#  attr_accessor :current_user
  self.table_name = 'traits_and_yields_view'


  #--
  ### Module Usage ###

  include ActiveModel::Serialization

  extend CoordinateSearch # provides coordinate_search

  extend DataAccess # provides all_limited

  extend SimpleSearch

  extend AdvancedSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ scientificname commonname trait
                      trait_description city sitename author
                      citation_year }




  #--
  ### Scopes ###

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES).order("id asc") }
  scope :search, lambda { |search| where(advanced_search(search)) }
  scope :checked, lambda { |checked_minimum| where("checked >= #{checked_minimum}") }

  # MAYBE SET SCOPE HERE?

  # make NumberHelper available to use inside comma block:
  extend ActionView::Helpers::NumberHelper




  #--
  ### CSV Format ###

  comma do
    checked 'checked' do |num|
      if num == 1 then
        'checked'
      else
        'unchecked'
      end
    end
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



  #--
  ### Presentation Methods ###

  def pretty_date
    if date.nil?
      '[unspecified]'
    else
      date_in_site_timezone.to_formatted_s(date_format) + " (#{site_timezone})"
    end
  end

  private

  # Convert the Trait date attribute (which is an ActiveSupport::TimeWithZone
  # object) to a new TimeWithZone object representing the time in site_timezone.
  # This is used in various methods used for presenting the date and time to the
  # user, which is always done in local (site) time.
  def date_in_site_timezone
    date.in_time_zone(site_timezone)
  end

  # Returns the time zone of the associated site or "UTC" if no there is no
  # associated site or if its time_zone attribute is blank.
  def site_timezone
    begin
      zone = (Site.find(site_id)).time_zone
      if zone.blank?
        zone = 'UTC'
      end
    rescue
      zone = 'UTC' # site not found
    end
    return zone
  end

  def date_format
    case dateloc
    when 9
      :no_date_data
    when 8
      :year_only
    when 7
      :season_and_year
    when 6
      :month_and_year
    when 5.5
      :week_of_year
    when 5
      :year_month_day
    when 97
      :season_only
    when 96
      :month_only
    when 95
      :month_day
    when nil
      :unspecified_dateloc
    else
      :unrecognized_dateloc
    end
  end

end
