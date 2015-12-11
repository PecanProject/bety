class Site < ActiveRecord::Base

  include Overrides

  def as_json(options = {})
    options[:except] = [:clay_pct, :created_at, :id, :local_time, :map, :mat,
                        :sand_pct, :soil, :soilnotes, :som, :updated_at, :user_id]
    super(options)
  end

  def to_xml(options = {})
    options[:except] = [:clay_pct, :created_at, :id, :local_time, :map, :mat,
                        :sand_pct, :soil, :soilnotes, :som, :updated_at, :user_id]
    super(options)
  end

  def lat
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
    val = val.blank? ? 0.0 : val
    if not self[:geometry] then
      self[:geometry] = "SRID=4326;Point(0 #{val} 0)"
    else
      self[:geometry] = "SRID=#{espg};Point(#{lon} #{val} #{masl})"
    end;
  end

  def lon
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
    val = val.blank? ? 0.0 : val
    if not self[:geometry] then
      self[:geometry] = "SRID=4326;Point(#{val} 0 0)"
    else
      self[:geometry] = "SRID=#{espg};Point(#{val} #{lat} #{masl})"
    end
  end

  # Returns true if the site geometry is null or has type 'ST_Point'.
  def point?
    geometry.nil? || geometry.geometry_type.type_name == 'Point'
  end

  def masl
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
    val = val.blank? ? 0.0 : val
    if not self[:geometry] then
      self[:geometry] = "SRID=4326;Point(0 0 #{val})"
    else
      self[:geometry] = "SRID=#{espg};Point(#{lon} #{lat} #{val})"
    end
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

  extend CoordinateSearch # provides coordinate_search

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ sites.sitename sites.city sites.state sites.country }

  has_many :citation_sites, :class_name => "CitationsSites"
  has_many :citations, :through =>  :citation_sites

  has_many :yields
  has_many :traits
  has_many :runs
  has_many :inputs

  belongs_to :user

  # VALIDATION

  ## Validation methods

  def sum_of_soil_percentages_does_not_exceed_100
    if sand_pct + clay_pct > 100
      errors.add(:base, "Sand and Clay percentages can't add up to more than 100")
    end
  end

  ## Validation callbacks

  before_validation WhitespaceNormalizer.new([:sitename, :city, :state, :country])
  before_validation :warn_about_elevation_update_bug, on: :update

  ## Validations

  validates_numericality_of :mat, greater_that_or_equal_to: -25, less_than_or_equal_to: 40,
      unless: Proc.new { |a| a.mat.blank? }
  validates_numericality_of :map, greater_that_or_equal_to: 0, less_than_or_equal_to: 12000,
      unless: Proc.new { |a| a.map.blank? }
  validates_numericality_of :som, greater_that_or_equal_to: 0, less_than_or_equal_to: 100,
      unless: Proc.new { |a| a.som.blank? }
  validates_numericality_of :sand_pct, greater_that_or_equal_to: 0, less_than_or_equal_to: 100,
      unless: Proc.new { |a| a.sand_pct.blank? }
  validates_numericality_of :clay_pct, greater_that_or_equal_to: 0, less_than_or_equal_to: 100,
      unless: Proc.new { |a| a.clay_pct.blank? }
  validate :sum_of_soil_percentages_does_not_exceed_100, unless: Proc.new { |a| a.sand_pct.nil? || a.clay_pct.nil? }
  validates_presence_of :sitename
  validates_presence_of :lat, :lon
  validates_numericality_of :lat, greater_than_or_equal_to: -90 , less_than_or_equal_to: 90, if: Proc.new { |s| s.point? }
  validates_numericality_of :lon, greater_than_or_equal_to: -180 , less_than_or_equal_to: 180, if: Proc.new { |s| s.point? }
  validates_numericality_of :masl,
    greater_than_or_equal_to: -418,
    less_than_or_equal_to: 8848, # Mount Everest
    message: "Elevation must be between -418 and 8848 meters",
    if: Proc.new { |s| s.point? }

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
    sites = self.where({})
    citation_id_list.flatten.each do |citation_id|
      sites = sites.where(where_condition, citation_id)
    end
    return sites
  end

  scope :all_order, :order => 'country, state, city'
  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }
  scope :minus_already_linked, lambda {|citation|
    if citation.nil? || citation.sites.size == 0
      {}
    else
      where("id not in (?)", citation.sites.collect(&:id))
    end
  }

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

  def warn_about_elevation_update_bug
    if @masl_updated && !@lat_or_lon_updated
      self.masl = @old_masl # revert elevation in form
      errors.add(:masl, "Elevation can be updated only if latitude or longitude is also updated")
    end
  end


  #Columns we search when referenced from another model
  #Fields present in 'select_default'
#  def self.search_columns
#    return ["sites.id", "sites.sitename", "sites.city", "sites.state", "sites.country"]
#  end
end
