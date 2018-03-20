class Site < ActiveRecord::Base
  attr_protected []

  #--
  ### Module Usage ###

  include Overrides

  extend CoordinateSearch # provides coordinate_search

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ sites.sitename sites.city sites.state sites.country }

  #--
  ### Associations ###

  has_many :citation_sites, :class_name => "CitationsSites"
  has_many :citations, :through =>  :citation_sites

  has_many :sitegroups_sites, :class_name => "SitegroupsSites"
  has_many :sitegroups, :through =>  :sitegroups_sites

  has_many :experiments_sites
  has_many :experiments, :through =>  :experiments_sites
  
  has_many :sites_cultivars, :class_name => "SitesCultivars"
  has_many :cultivars, :through =>  :sites_cultivars

  has_many :yields
  has_many :traits
  has_many :runs
  has_many :inputs

  belongs_to :user

  #--
  ### Format Definition ###

  def as_json(options = {})
    options[:except] = [:clay_pct, :created_at, :id, :map, :mat,
                        :sand_pct, :soil, :soilnotes, :som, :updated_at, :user_id]
    super(options)
  end

  def to_xml(options = {})
    options[:except] = [:clay_pct, :created_at, :id, :map, :mat,
                        :sand_pct, :soil, :soilnotes, :som, :updated_at, :user_id]
    super(options)
  end

  comma do
    id
    city
    state
    country
    lat
    lon
    created_at
    updated_at
    sitename
    greenhouse
  end

  #--
  ### Scopes ###

  scope :all_order, -> { order('country, state, city') }
  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES).references(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }
  scope :minus_already_linked, lambda {|citation|
    if citation.nil? || citation.sites.size == 0
      all
    else
      where("id not in (?)", citation.sites.collect(&:id))
    end
  }

  #--
  ### Callbacks ###

  before_save :assign_geometry, if: :setting_geometry?

  #### Validation callbacks

  before_validation WhitespaceNormalizer.new([:sitename, :city, :state, :country])
  before_validation :warn_about_elevation_update_bug, on: :update

  #--
  ### Virtual Attributes for Geometry

  def lat
    if !@lat.nil?
      return @lat
    end
    if self[:geometry]
      if self[:geometry].geometry_type.type_name == 'Point'
        return self[:geometry].y
      else
        return self[:geometry].centroid.y
      end
    else
      return nil
    end
  end

  def lat=(val)
    if val.to_f != lat
      @lat_or_lon_updated = true
    end
    @lat = val
  end

  def lon
    if !@lon.nil?
      return @lon
    end
    if self[:geometry]
      if self[:geometry].geometry_type.type_name == 'Point'
        return self[:geometry].x
      else
        return self[:geometry].centroid.x
      end
    else
      return nil
    end
  end

  def lon=(val)
    if val.to_f != lon
      @lat_or_lon_updated = true
    end
    @lon = val
  end

  # Returns true if the site geometry is null or has type 'ST_Point'.
  def point?
    geometry.nil? || geometry.geometry_type.type_name == 'Point'
  end

  def masl
    if !@masl.nil?
      return @masl
    end
    if self[:geometry]
      if self[:geometry].geometry_type.type_name == 'Point'
        return self[:geometry].z
      else
        return nil # self[:geometry].centroid.z is always NaN, so return nil
      end
    else
      return nil
    end
  end

  def masl=(val)
    if val.to_f != masl
      @masl_updated = true
      @old_masl = masl
    end
    @masl = val
  end

  def espg
    return self[:geometry] ? self[:geometry].srid : nil
  end

  def espg=(val)
    if not self[:geometry] then
      self[:geometry] = "SRID=#{val};Point(0 0 0)"
    else
      self[:geometry] = "SRID=#{val};Point(#{lon} #{lat} #{masl})"
    end;
  end

  # VALIDATION

  ## Validations

  validates_numericality_of :mat, greater_that_or_equal_to: -25, less_than_or_equal_to: 40,
      allow_blank: true
  validates_numericality_of :map, greater_that_or_equal_to: 0, less_than_or_equal_to: 12000,
      allow_blank: true
  validates_numericality_of :som, greater_that_or_equal_to: 0, less_than_or_equal_to: 100,
      allow_blank: true
  validates_numericality_of :sand_pct, greater_that_or_equal_to: 0, less_than_or_equal_to: 100,
      allow_blank: true
  validates_numericality_of :clay_pct, greater_that_or_equal_to: 0, less_than_or_equal_to: 100,
      allow_blank: true
  validate :sum_of_soil_percentages_does_not_exceed_100, unless: Proc.new { |a| a.sand_pct.nil? || a.clay_pct.nil? }
  validates_presence_of :sitename
  validates_numericality_of :lat, greater_than_or_equal_to: -90 , less_than_or_equal_to: 90, allow_blank: true
  validates_numericality_of :lon, greater_than_or_equal_to: -180 , less_than_or_equal_to: 180, allow_blank: true
  validates_numericality_of :masl,
    greater_than_or_equal_to: -418,
    less_than_or_equal_to: 8848, # Mount Everest
    message: "Elevation must be between -418 and 8848 meters",
    allow_blank: true
  validate :complete_geometry_specification # Check either all coordinates are specified or none.

  # Returns an +ActiverRecord::Relation containing all Site objects that are
  # associated with every Citation whose id is in +citation_id_list+.
  # +citation_id_list+ may be given as a single Array, as multiple integer
  # arguments, or as some combination of the two.
  def self.in_all_citations(*citation_id_list)
    where_condition = <<"CONDITION"
EXISTS (
    SELECT 1 FROM citations_sites cs
        WHERE cs.site_id = sites.id
            AND cs.citation_id = ?)
CONDITION
    sites = nil
    citation_id_list.flatten.each do |citation_id|
      if sites.nil?
        sites = self.where(where_condition, citation_id)
      else
        sites = sites.where(where_condition, citation_id)
      end
    end
    return sites
  end

  #--
  ### Display Methods ###

  def lat_lon_soiltype
    "#{lat},#{lon} - #{soil}"
  end

  def city_state
    #city = city.chomp if !city.nil?
    "#{city} #{state}"
  end

  def sitename_state_country
    output = ""
    
    #city = city.chomp if !city.nil?
    if !sitename.blank?
      output += "#{sitename}"
    end
    if !sitename.blank? and (!city.blank? or !state.blank? or !country.blank?)
      output += " -"
    end
    if !city.blank?
      output += " #{city}"
    end
    if !state.blank?
      output += " #{state}"
    end
    if !country.blank?
      output += ", #{country}"
    end
    output
  end

  def to_s
    sitename_state_country
  end
  def select_default
    "#{id}: #{self}"
  end

  def autocomplete_label
    "#{sitename.squish} (#{city.squish}, #{!(state.nil? || state.empty?) ? " #{state.squish}," : ""} #{country.squish})"
  end

  private

  ## Validation methods

  def sum_of_soil_percentages_does_not_exceed_100
    if sand_pct + clay_pct > 100
      errors.add(:base, "Sand and Clay percentages can't add up to more than 100")
    end
  end

  def complete_geometry_specification
    case
    when !lat.blank? && !lon.blank? && masl.blank?
      errors.add(:masl, "Elevation must be specified when setting a geometry")
    when lat.blank? && !lon.blank? && !masl.blank?
      errors.add(:lat, "Latitude must be specified when setting a geometry")
    when !lat.blank? && lon.blank? && !masl.blank?
      errors.add(:lon, "Longitude must be specified when setting a geometry")
    when !lat.blank? && lon.blank? && masl.blank?
      errors.add(:lat, "If you specify a latitude, you must specify longitude and elevation")
    when lat.blank? && !lon.blank? && masl.blank?
      errors.add(:masl, "If you specify a longitude, you must specify latitude and elevation")
    when lat.blank? && lon.blank? && !masl.blank?
      errors.add(:masl, "If you specify an elevation, you must specify latitude and longitude")
    end # case
  end


  # A bug (or feature?) in the postgis adapter prevents updating the elevation
  # unless the latitude or longitude changes.
  def warn_about_elevation_update_bug
    if @masl_updated && !@lat_or_lon_updated
      self.masl = @old_masl # revert elevation in form
      errors.add(:masl, "Elevation can be updated only if latitude or longitude is also updated")
    end
  end


  def setting_geometry?
    @lat_or_lon_updated || @masl_updated
  end

  # Handle virtual geometry attributes when saving:
  def assign_geometry
    if not self[:geometry] then
      self[:geometry] = "SRID=4326;Point(#{lon} #{lat} #{masl})"
    else
      # If lon, lat, and masl are all blank, this sets the geometry to null.
      self[:geometry] = "SRID=#{espg};Point(#{lon} #{lat} #{masl})"
    end
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
#  def self.search_columns
#    return ["sites.id", "sites.sitename", "sites.city", "sites.state", "sites.country"]
#  end
end
