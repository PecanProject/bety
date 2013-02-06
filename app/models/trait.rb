class Trait < ActiveRecord::Base
  # Passed from controller for validation of ability
  attr_accessor :current_user

  include Overrides

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

  validates_presence_of     :mean
  validates_presence_of     :statname, :if => Proc.new { |trait| !trait.stat.blank? }
  validates_format_of       :date_year, :with => /^(\d{2}|\d{4})$/, :allow_blank => true
  validates_format_of       :date_month, :with => /^\d{1,2}$/, :allow_blank => true
  validates_format_of       :date_day, :with => /^\d{1,2}$/, :allow_blank => true
  validates_format_of       :time_hour, :with => /^\d{1,2}$/, :allow_blank => true
  validates_format_of       :time_minute, :with => /^\d{1,2}$/, :allow_blank => true
  validate :can_change_checked

  # Only allow admins/managers to change traits marked as failed.
  def can_change_checked
    errors.add(:checked, "You do not have permission to change") if
      checked == -1 and current_user.page_access_level > 2
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
  def self.all_limited(current_user)
    if !current_user.nil?
      if current_user.page_access_level == 1
        checked = -1
        access_level = 1
      elsif current_user.page_access_level <= 2
        checked = -1
        access_level = current_user.access_level
      else
        checked = 1
        access_level = current_user.access_level
      end
      user = current_user
    else
      user = 1000000000000
      checked = 1
      access_level = 4
    end

    where("(checked >= ? and access_level >= ?) or traits.user_id = ?",checked,access_level,user)
  end


  comma do
    id
    site_id
    specie_id
    citation_id
    cultivar_id
    treatment_id
    entity_id
    date_year
    date_month
    date_day
    dateloc
    time_hour
    time_minute
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
    date_string = ""
    date_string += "#{date_year} " unless date_year.nil?
    date_string += "#{Date::ABBR_MONTHNAMES[date_month]} " unless date_month.nil?
    date_string += "#{date_day} " unless date_day.nil?
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
    time_string = ""
    time_string += "#{time_hour}" unless time_hour.nil?
    time_string += ":#{time_minute}" unless time_hour.nil? or time_minute.nil?
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

end
