class Site < ActiveRecord::Base

  include Overrides

  extend CoordinateSearch # provides coordinate_search

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ sites.sitename sites.city sites.state sites.country sites.lat sites.lon sites.espg }

  has_many :citation_sites, :class_name => "CitationsSites"
  has_many :citations, :through =>  :citation_sites

  has_many :yields
  has_many :traits
  has_many :runs
  has_many :inputs

  belongs_to :user

  scope :all_order, :order => 'country, state, city'
  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }
  scope :minus_already_linked, lambda {|citation|
    if citation.nil?
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
    mat
    map
    masl
    soil
    som
    notes
    soilnotes
    created_at
    updated_at
    sitename
    greenhouse
    user_id
    local_time
    sand_pct
    clay_pct
    espg
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
