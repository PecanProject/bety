class Trait < ActiveRecord::Base

  #--
  ### Module Usage ###

  include Overrides

  extend DataAccess # provides all_limited

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ citation variable specie site treatment }
  SEARCH_FIELDS = %w{ traits.id traits.mean traits.n traits.stat traits.statname variables.name species.genus citations.author sites.sitename treatments.name }



  #--
  ### Associations ###

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

  

  #--
  ### Scopes ###

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



  #--
  ### Callbacks ###

  before_save :process_datetime_input



  #--
  ### Constants ###

  Seasons = ['Spring', 'Summer', 'Autumn', 'Winter']
  TimesOfDay = ['morning', 'mid-day', 'afternoon', 'night']



  #--
  ### Virtual Attributes ###

  # Passed from controller for validation of ability
  attr_accessor :current_user

  attr_writer :d_year
  attr_writer :d_month
  attr_writer :d_day
  attr_writer :t_hour
  attr_writer :t_minute


  #--
  ## Custom accessors for virtual attributes. ##

  # A getter for the +d_year+ virtual attribute.  If the @+d_year+ instance
  # variable has been set, it is used.  (This occurs, for example, when
  # returning to a form that failed validation.)  Otherwise, the value is
  # computed from these persistent (i.e., database-backed) attributes: date,
  # dateloc, and site.time_zone.
  def d_year
    if !@d_year.nil?
      return @d_year
    end

    case dateloc
    when 95, 96, 97, 9
      ''
    when 5, 5.5, 6, 7, 8
      date.nil? ? '' : date_in_site_timezone.year
    when nil
      nil
    else
      raise
    end
  end

  # A getter for the +d_month+ virtual attribute.  If the @+d_month+ instance
  # variable has been set, it is used.  (This occurs, for example, when
  # returning to a form that failed validation.)  Otherwise, the value is
  # computed from these persistent (i.e., database-backed) attributes: date,
  # dateloc, and site.time_zone.
  def d_month
    if !@d_month.nil?
      return @d_month
    end

    case dateloc
    when 8, 9
      nil
    when 7, 97
      case date_in_site_timezone.month
      when 1
        'Winter'
      when 4
        'Spring'
      when 7
        'Summer'
      when 10
        'Autumn'
      else
        raise
      end
    when 5, 5.5, 6, 95, 96
      date.nil? ? '' : date_in_site_timezone.month
    when nil
      nil
    else
      raise
    end
  end

  # A getter for the +d_day+ virtual attribute.  If the @+d_day+ instance
  # variable has been set, it is used.  (This occurs, for example, when
  # returning to a form that failed validation.)  Otherwise, the value is
  # computed from these persistent (i.e., database-backed) attributes: date,
  # dateloc, and site.time_zone.
  def d_day
    if !@d_day.nil?
      return @d_day
    end

    case dateloc
    when 6, 7, 8, 9, 96, 97
      nil
    when 5, 5.5, 95
      date.nil? ? '' : date_in_site_timezone.day
    when nil
      nil
    else
      raise
    end
  end

  # A getter for the +t_hour+ virtual attribute.  If the @+t_hour+ instance
  # variable has been set, it is used.  (This occurs, for example, when
  # returning to a form that failed validation.)  Otherwise, the value is
  # computed from these persistent (i.e., database-backed) attributes: date,
  # dateloc, and site.time_zone.
  def t_hour
    if !@t_hour.nil?
      return @t_hour
    end

    case timeloc
      when 9
      nil
    when 4
      'morning'
    when 1, 2, 3
      date.nil? ? '' : date_in_site_timezone.strftime('%H')
    when nil
      nil
    else
      raise
    end
  end

  # A getter for the +t_minute+ virtual attribute.  If the @+t_minute+ instance
  # variable has been set, it is used.  (This occurs, for example, when
  # returning to a form that failed validation.)  Otherwise, the value is
  # computed from these persistent (i.e., database-backed) attributes: date,
  # dateloc, and site.time_zone.
  def t_minute
    if !@t_minute.nil?
      return @t_minute
    end

    case timeloc
    when 3, 4, 5, 9
      nil
    when 1, 2
      date.nil? ? '' : date_in_site_timezone.strftime('%M')
    when nil
      nil
    else
      raise
    end
  end

  # Returns the time zone of the associated site or "UTC" if no there is no
  # associated site or if its time_zone attribute is blank.
  def site_timezone
    begin
      zone = site.time_zone
      if zone.blank?
        zone = 'UTC'
      end
    rescue
      zone = 'UTC' # site not found
    end
    return zone
  end



  #--
  ### VALIDATION ###

  #--
  ## Validation methods ##

  # Validation Method: Check that the five time/date fields represent a valid
  # date and time and are consistent with our conventions for allowable partial
  # information about dates and times.
  def consistent_date_and_time_fields

    # Set defaults for unspecified components and convert the supplied ones to
    # integers.
    case computed_dateloc
    when 9
      year, month, day = 9996, 1, 1
    when 8
      year, month, day = d_year.to_i, 1, 1
    when 7
      case d_month
      when 'Spring'
        month = 4
      when 'Summer'
        month = 7
      when 'Autumn'
        month = 10
      when 'Winter'
        month = 1
      end
      year, day = d_year.to_i, 1
    when 6
      year, month, day = d_year.to_i, d_month.to_i, 1
    when 5
      year, month, day = d_year.to_i, d_month.to_i, d_day.to_i
    when 97
      case d_month
      when 'Spring'
        month = 4
      when 'Summer'
        month = 7
      when 'Autumn'
        month = 10
      when 'Winter'
        month = 1
      end
      year, day = 9996, 1
    when 96
      year, month, day = 9996, d_month.to_i, 1
    when 95
      year, month, day = 9996, d_month.to_i, d_day.to_i
    end

    hour, minute = t_hour.to_i, t_minute.to_i
    # This will catch some illegal dates (1900-02-29, for example) that Time.new
    # will silently covert to an acceptible date (1900-03-01, in this example).
    DateTime.new(year, month, day, hour, minute)

    @computed_date = utctime_from_sitetime(year, month, day, hour, minute)
  rescue => e
    errors.add(:base, e.message)
  end

  # Validation Method: Only allow admins/managers to change traits marked as failed.
  def can_change_checked
    errors.add(:checked, "You do not have permission to change") if
      checked == -1 and current_user.page_access_level > 2
  end

  # Validation Method: Check that the mean is in the range stipulated for the variable.
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


  #--
  ## Validations ##

  validates_presence_of     :mean, :access_level, :site
  validates_numericality_of :mean
  validates_presence_of     :variable
  validates_inclusion_of    :access_level, in: 1..4, message: "You must select an access level"
  validates_presence_of     :statname, :if => Proc.new { |trait| !trait.stat.blank? }
  validates_format_of       :d_year, :with => /\A(\d{2}|\d{4})\z/, :allow_blank => true
  validates_format_of       :d_month, :with => /\A\d{1,2}|Spring|Summer|Winter|Autumn\z/, :allow_blank => true
  validates_format_of       :d_day, :with => /\A\d{1,2}\z/, :allow_blank => true
  #validates_format_of       :t_hour, :with => /\A\d{1,2}\z/, :allow_blank => true
  validates_format_of       :t_minute, :with => /\A\d{1,2}\z/, :allow_blank => true
  #validates_format_of        :timezone_offset, :with => /\A *[+-]?([01]?[0-9]|2[0-3]):(00|15|30|45):00 *\z/
  validate :consistent_date_and_time_fields
  validate :can_change_checked
  validate :mean_in_range



  #--
  ### CSV Formats ###

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


  
  #--
  ### Presentation Methods ###

  def pretty_date
    date.nil? ? '[unspecified]' : date_in_site_timezone.to_formatted_s(date_format) + ([7, 9, 97].include?(dateloc) || timeloc != 9 ? '' : " (#{site_timezone})")
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
#    Rails.logger.info("date = #{date.to_s}; date.to_s(time_format) = #{date.to_s(time_format)}")
    date.nil? ? '[unspecified]' : date_in_site_timezone.to_s(time_format) + (timeloc == 9 ? '' : " (#{site_timezone})")
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

  # Computes the values to store for date, dateloc, and timeloc based on the
  # values of the virtual attributes.
  def process_datetime_input
    self.dateloc = computed_dateloc
    self.timeloc = computed_timeloc
    self.date = @computed_date # this is set in the consistent_date_and_time_fields validate method
  end


  def computed_dateloc
    # Convenience variables; since we only use this method in cases where the
    # accessor returns exactly the same value as the instance variable, we may
    # as well use the latter since it's faster.
    y = @d_year
    m = @d_month
    d = @d_day

    if !d.blank?
      if m.blank?
        raise "If you set a day, you must also set a month."
      elsif Seasons.include?(m)
        raise "If you select a season, day must be blank."
      else
        if y.blank?
          95
        else
          5
        end
      end
    else # d is blank
      if m.blank?
        if y.blank?
          9
        else
          8
        end
      elsif Seasons.include?(m)
        if y.blank?
          97
        else
          7
        end
      else # month is a number (a real month)
        if y.blank?
          96
        else
          6
        end
      end
    end
  end

  def computed_timeloc
    if @t_hour.blank?
      if !@t_minute.blank?
        # shouldn't ever get here
        raise "If you specify minutes, you must specify the hour.!"
      end
      9
    else # hour is given
      if @t_minute.blank?
        3
      else
        2
      end
    end
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

  def time_format
    case timeloc
    when 9 
      :no_time_data
    when 4 
      :time_of_day
    when 3 
      :hour_only
    when 2 
      :hour_minutes
    when 1 
      :hour_minutes_seconds
    when nil
      :unspecified_timeloc
    else
      :unrecognized_timeloc
    end
  end
  
  def utctime_from_sitetime(y, m, d, hr, min)
    utctime = nil
    Time.use_zone site_timezone do
      utctime = Time.zone.local(y, m, d, hr, min, 0).utc
    end
    return utctime.to_datetime
  end

  # Convert the Trait date attribute (which is an ActiveSupport::TimeWithZone
  # object) to a new TimeWithZone object representing the time in site_timezone.
  # This is used in various methods used for presenting the date and time to the
  # user, which is always done in local (site) time.
  def date_in_site_timezone
    date.in_time_zone(site_timezone)
  end
  
end
