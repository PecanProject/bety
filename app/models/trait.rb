class Trait < ActiveRecord::Base
  # Passed from controller for validation of ability
  attr_accessor :current_user

  attr_accessor :timezone_offset, :d_year, :d_month, :d_day, :t_hour, :t_minute

  def d_year
    Rails.logger.info("In method d_year, @d_year = #{@d_year}")
    @d_year || (date.nil? ? '' : date.utc.year)
  end
  def d_month
    @d_month || (date.nil? ? '' : date.utc.month)
  end
  def d_day
    @d_day || (date.nil? ? '' : date.utc.day)
  end
  def t_hour
    @t_hour || (date.nil? ? '' : date.utc.hour)
  end
  def t_minute
    # use formatting to make sure value matches dropdown values:
    @t_minute || (date.nil? ? '' : date.utc.min)
  end
  def timezone_offset
    @timezone_offset.nil? ?  "+00:00:00" : (@timezone_offset.match(/\+|-/) ? @timezone_offset : "+#{@timezone_offset}")
    #Rails.logger.info("In t_hour, date.utc = #{self.date.utc} and date.utc.hour = #{date.utc.hour}")
  end

  before_save :apply_offset

  include Overrides

  extend DataAccess # provides all_limited

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ citation variable specie site treatment }
  SEARCH_FIELDS = %w{ traits.id traits.mean traits.n traits.stat traits.statname variables.name species.genus citations.author sites.sitename treatments.name }

  has_many :covariates
  has_many :variables, :through => :covariates

  belongs_to :variable
  belongs_to :site
  belongs_to :specie
  belongs_to :citation
  belongs_to :treatment
  belongs_to :cultivar
  belongs_to :user
  belongs_to :entity
  belongs_to :ebi_method, :class_name => 'Methods', :foreign_key => 'method_id'



  # VALIDATION

  ## Validation methods

  def consistent_date_and_time_fields

    # Require a month if there is a day:
    if @d_month.blank? && !@d_day.blank?
      errors.add(:base, "If you have a date day, you must specify the month.")
    end

    # Require an hour if minutes are specified:
    if @t_hour.blank? && !@t_minute.blank?
      errors.add(:base, "If you specify minutes, you must specify the hour.")
    end

    # Require a timezone offset if the hour is specified:
    if timezone_offset.blank? && !@t_hour.blank?
      errors.add(:base, "If you specify the hour, you must specify a timezone offset.")
    end

    if !timezone_offset.blank? && !site_id.blank?
      # estimate time zone from site longitude
      appx_offset = (Site.find site_id).lon / 15.0
      hour_offset = (timezone_offset.sub(/:.*/, '')).to_i
      if(appx_offset - hour_offset).abs > 2
        errors.add(:base, "The UTC offset value you have selected seems inconsistent with the site location.")
      end
    end
      

    begin
      #t = DateTime.new(@d_year.to_i, @d_month.to_i, @d_day.to_i, @t_hour.to_i, @t_minute.to_i, 0, timezone_offset)
    rescue => e
      errors.add(:base, e.message)
    end
  end

  ## Validation callback methods

  ## Validation callbacks

  ## Validations

  validates_presence_of     :mean, :access_level
  validates_numericality_of :mean
  validates_presence_of     :variable
  validates_inclusion_of    :access_level, in: 1..4, message: "You must select an access level"
  validates_presence_of     :statname, :if => Proc.new { |trait| !trait.stat.blank? }
  validates_format_of       :d_year, :with => /\A(\d{2}|\d{4})\z/, :allow_blank => true
  validates_format_of       :d_month, :with => /\A\d{1,2}\z/, :allow_blank => true
  validates_format_of       :d_day, :with => /\A\d{1,2}\z/, :allow_blank => true
  #validates_format_of       :t_hour, :with => /\A\d{1,2}\z/, :allow_blank => true
  validates_format_of       :t_minute, :with => /\A\d{1,2}\z/, :allow_blank => true
  #validates_format_of        :timezone_offset, :with => /\A *[+-]?([01]?[0-9]|2[0-3]):(00|15|30|45):00 *\z/
  validate :consistent_date_and_time_fields
  validate :can_change_checked
  validate :mean_in_range


  # Only allow admins/managers to change traits marked as failed.
  def can_change_checked
    errors.add(:checked, "You do not have permission to change") if
      checked == -1 and current_user.page_access_level > 2
  end

  # To do: change the database type of min and max and constrain to be
  # non-null so that these tests can be simplified.
  def mean_in_range
    return if mean.blank? || variable.blank? # validates_presence_of should handle this error
    if variable.min != "-Infinity" and mean < variable.min.to_f
      errors.add(:mean, "The value of mean for the #{variable.name} trait must be at least #{variable.min}.")
    end
    if variable.max != "Infinity" and mean > variable.max.to_f
      errors.add(:mean, "The value of mean for the #{variable.name} trait must be at most #{variable.max}.")
    end
  end

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }
  scope :exclude_api, where("checked != ?","-1")
  scope :citation, lambda { |citation|
    if citation.nil?
      {}
    else
      where("citation_id = ?", citation)
    end
  }

  comma do
    id
    site_id
    specie_id
    citation_id
    cultivar_id
    treatment_id
    entity_id
    d_year
    d_month
    d_day
    dateloc
    t_hour
    t_minute
    timeloc
    mean
    n
    statname
    stat
    notes
    created_at
    updated_at
    variable_id
    user_id
    checked
    access_level
  end

  comma :test_pat do
    access_level
  end

  comma :show_traits do
    site :city_state
    specie :scientificname
    cultivar :sn_name
    citation :author_year
  end

  comma :maps_traits do
    specie :genus_species
    variable :name_units => 'Trait Name'
    mean
    n
    statname do |s|
      if s.nil? or s.blank? or s == "none"
        "NULL"
      else
        s
      end
    end
    stat do |s|
      if s.nil? or s.blank? or s == "none"
        "NULL"
      else
        s
      end
    end
    site :sitename_state_country => 'Site Name'
    treatment :name_definition => 'Treatment'
    citation :author_year_title => 'Author Year Title' 
    site :lat => 'Latitude', :lon => 'Longitude'
  end

  def pretty_date
    date.to_formatted_s(date_format)
  end

  def format_statname
    if statname.nil? or statname.blank? or statname == "none"
      "NULL"
    else
      statname
    end
  end

  def format_stat
    if stat.nil? or stat.blank? or stat == "none"
      "NULL"
    else
      stat
    end
  end

  def pretty_time
    time.nil? ? '[unspecified]' : time.to_s(time_format)
  end

  def specie_treat_cultivar
    "#{specie} - #{variable} - #{treatment} - #{citation}"
  end

  def to_s
    specie_treat_cultivar
  end

  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["traits.id"]
  end



  private

  def apply_offset


    # Supply missing year if needed:

    if @d_year.blank?
      @d_year = 9996
      self.dateloc = 95
    end


=begin
    sign, hour, minutes = /\A *([+-]?)(\d\d?):(\d\d) *\z/.match(self.timezone_offset).captures

    Rails.logger.info("self.timezone_offset: #{self.timezone_offset}")
    Rails.logger.info("sign, hour, minutes: #{sign}, #{hour}, #{minutes}")

    if sign == "-"
      sign = -1
    else 
      sign = 1
    end

    hour = hour.to_i
    minutes = minutes.to_i

    # convert time to UTC : UTC time = local time - local time offset
    Rails.logger.info("@t_hour: #{@t_hour}")
    Rails.logger.info("sign * hour: #{sign * hour}")
    Rails.logger.info("@t_hour - sign * hour: #{@t_hour - sign * hour}")
    self.@t_hour -= sign * hour
    self.@t_minute -= sign * minutes

    self.notes = "blah"

    Rails.logger.info("self = #{self}")
=end
    begin
      t_utc = DateTime.new(@d_year.to_i, @d_month.to_i, @d_day.to_i, @t_hour.to_i, @t_minute.to_i, 0, timezone_offset).utc
    rescue => e
      Rails.logger.info("in apply offset, got this error: #{e.message}")
      Rails.logger.info("values of @d_year, @d_month, @d_day, @t_hour, @t_minute are #{@d_year}, #{@d_month}, #{@d_day}, #{@t_hour}, #{@t_minute} with types #{@d_year.class}, #{@d_month.class}, #{@d_day.class}, #{@t_hour.class}, #{@t_minute.class}")
      return false
    end
      Rails.logger.info("values of @d_year, @d_month, @d_day, @t_hour, @t_minute are #{@d_year}, #{@d_month}, #{@d_day}, #{@t_hour}, #{@t_minute} with types #{@d_year.class}, #{@d_month.class}, #{@d_day.class}, #{@t_hour.class}, #{@t_minute.class}")
    Rails.logger.info("t_utc = #{t_utc}")
    
    if t_utc.year == 9995 || t_utc.year == 9997
      t_utc.change(year: 9996)
    end

    self.date = t_utc


  end


  private

  def date_format
    case dateloc
    when      9 
      :no_date_data
    when      8 
      :year_only
    when      7 
      :season_and_year
    when      6 
      :month_and_year
    when      5.5 
      :week_of_year
    when      5 
      :year_month_day
    when      97 
      :season_only
    when      96 
      :month_only
    when      95 
      :month_day
    when nil
      :unspecified_dateloc
    else
      :unrecognized_dateloc
    end
  end

  def time_format
    case timeloc
    when      9 
      :no_time_data
    when      4 
      :time_of_day
    when      3 
      :hour_only
    when      2 
      :hour_minutes
    when      1 
      :hour_minutes_seconds
    when nil
      :unspecified_timeloc
    else
      :unrecognized_timeloc
    end
  end
  
  
  

    

end
