class Yield < ActiveRecord::Base

  #--
  ### Module Usage ###

  include Overrides

  extend DataAccess # provides all_limited

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ citation specie site treatment cultivar }
  SEARCH_FIELDS = %w{ species.genus cultivars.name yields.mean yields.n yields.stat yields.statname citations.author sites.sitename treatments.name }

  include DateTimeConstants

  #--
  ### Associations ###

  belongs_to :citation
  belongs_to :site
  belongs_to :specie
  belongs_to :treatment
  belongs_to :cultivar
  belongs_to :user
  belongs_to :ebi_method, :class_name => 'Methods', :foreign_key => 'method_id'



  #--
  ### VALIDATION ###

  #--
  ## Validation methods ##

  # Validation Method: Check that the three date fields represent a valid date
  # and are consistent with our conventions for allowable partial information
  # about dates.
  def consistent_date_and_time_fields

    # Set defaults for unspecified components and convert the supplied ones to
    # integers.
    case computed_dateloc
    when 9
      year, month, day = DummyYear, DummyMonth, DummyDay
    when 8
      year = julianyear.blank? ? d_year.to_i : julianyear.to_i
      month, day = DummyMonth, DummyDay
    when 7
      month = SeasonRepresentativeMonths[d_month]
      year, day = d_year.to_i, DummyDay
    when 6
      year, month, day = d_year.to_i, d_month.to_i, DummyDay
    when 5
      if !julianday.blank?
        @computed_date = Date.ordinal(julianyear.to_i, julianday.to_i)
        return
      end
      year, month, day = d_year.to_i, d_month.to_i, d_day.to_i
    when 97
      month = SeasonRepresentativeMonths[d_month]
      year, day = DummyYear, DummyDay
    when 96
      year, month, day = DummyYear, d_month.to_i, DummyDay
    when 95
      if !julianday.blank?
        @computed_date = Date.ordinal(DummyYear, julianday)
        return
      end
      year, month, day = DummyYear, d_month.to_i, d_day.to_i
    else
      raise "Unexpected computed_dateloc value in Trait#consistent_date_and_time_fields."
    end

    # Store the computed date for use by the before_save call-back "process_datetime_input".
    @computed_date = Date.new(year, month, day)

  rescue ArgumentError => e
      errors.add(:date, "is invalid")
  end


  validates_presence_of     :mean
  validates_numericality_of :mean, :greater_than_or_equal_to => 0.0
  validates_presence_of     :statname, :if => Proc.new { |y| !y.stat.blank? }

  validates_presence_of     :citation_id
  validates_presence_of     :site_id
  validates_presence_of     :specie_id
  validates_presence_of     :treatment_id
  validates_presence_of     :user_id
  validates_presence_of     :access_level
  validate :consistent_date_and_time_fields



  #--
  ### Scopes ###
  
  scope :all_order, includes(:specie).order('species.genus, species.species')
  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }
  scope :citation, lambda { |citation|
    if citation.nil?
      {}
    else
      where("citation_id = ?", citation)
    end
  }



  #--
  ### Callbacks ###

  before_save :process_date_input



  #--
  ### Virtual Attributes ###

  attr_writer :d_year
  attr_writer :d_month
  attr_writer :d_day

  # We don't need special getter methods for these because we always populate
  # the d_* fields, not these, when freshly populating the page form from the
  # database.
  attr_accessor :julianyear
  attr_accessor :julianday


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
      date.nil? ? '' : date.year
    when nil
      nil
    else
      raise "In d_year, unrecognized dateloc value."
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
      SeasonRepresentativeMonths.key(date.month) or
        raise "In d_month, month value is not appropriate for representing a season."
    when 5, 5.5, 6, 95, 96
      date.nil? ? '' : date.month
    when nil
      nil
    else
      raise "In d_month, unrecognized dateloc value."
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
      date.nil? ? '' : date.day
    when nil
      nil
    else
      raise "In d_day, unrecognized dateloc value."
    end
  end



  #--
  ### CSV Formats ###

  comma do
    id
    citation_id
    site_id
    specie_id
    treatment_id
    cultivar_id
    date
    dateloc
    statname
    stat
    mean
    n
    notes
    created_at
    updated_at
    user_id
    checked
    access_level
  end

  comma :test_pat do
    checked
  end

  comma :show_yields do |f|
     site :city_state
     specie :scientificname
     citation :author_year
     cultivar :sn_name
     treatment :name_definition

  end



  #--
  ### Presentation Methods ###

  def pretty_date
    if date.nil?
      '[unspecified]'
    else
      date.to_time.to_formatted_s(date_format)
    end
  end







  # Now that the access_level column of "yields" has user-defined (domain) type
  # "level_of_access", we have to ensure it maps to a Ruby Fixnum because Rails
  # seems to map unknown SQL types to strings by default:
  def access_level
    super.to_i
  end

  def to_s
    id
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["yields.id"]
  end




  private
  def process_date_input
    logger.info("computed_dateloc = #{computed_dateloc}")
    self.dateloc = computed_dateloc
    self.date = @computed_date # this is set in the consistent_date_and_time_fields validate method
  end


  def computed_dateloc
    # Convenience variables; since we only use this method in cases where the
    # accessor returns exactly the same value as the instance variable, we may
    # as well use the latter since it's faster.
    y = @d_year
    m = @d_month
    d = @d_day

    jy = @julianyear
    jd = @julianday

    if (!jy.blank? || !jd.blank?)
      if (!y.blank? || !m.blank? || !d.blank?)
        errors.add(:base, "If you set the Julian year or day, you must leave the other date fields blank.")
        return 9
      elsif jy.blank?
        return 95
      elsif jd.blank?
        return 8
      else
        return 5
      end
    end

    # We only get here if the Julian date fields are blank.

    if !d.blank?
      if m.blank?
        errors.add(:base, "If you set a day, you must also set a month.")
        9
      elsif Seasons.include?(m)
        errors.add(:base, "If you select a season, day must be blank.")
        9
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

  # provides date_format, and site_timezone
  include DateTimeUtilityMethods

end
