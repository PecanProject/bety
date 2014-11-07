class Site < ActiveRecord::Base

  include Overrides

  def to_json(options = {})
    options[:only] = [city, :state, :country, :lat, :lon, :sitename, :greenhouse, :notes]
    super(options)
  end

  def to_xml(options = {})
    options[:only] = [city, :state, :country, :lat, :lon, :sitename, :greenhouse, :notes]
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
    if not self[:geometry] then
      self[:geometry] = "SRID=4326;Point(#{val} 0 0)"
    else
      self[:geometry] = "SRID=#{espg};Point(#{val} #{lat} #{masl})"
    end
  end

  def masl
    if self[:geometry]
      if self[:geometry].geometry_type.type_name == 'Point'
        return self[:geometry].z
      else
        return self[:geometry].centroid.z
      end
    else
      return nil
    end
  end

  def masl=(val)
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


  #Columns we search when referenced from another model
  #Fields present in 'select_default'
#  def self.search_columns
#    return ["sites.id", "sites.sitename", "sites.city", "sites.state", "sites.country"]
#  end
end
