class Site < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ sites.sitename sites.city sites.state sites.country sites.lat sites.lon sites.espg }

  has_and_belongs_to_many :citations

  has_many :yields
  has_many :traits
  has_many :runs
  has_many :inputs

  belongs_to :user

  named_scope :all_order, :order => 'country, state, city'

  #20 miles
  #lat ~ miles/69.1
  #lng ~ miles/53.0
  named_scope :coordinate_search, lambda { |lat,lon,radius| { :conditions => { 
                                                                :lat => (lat-(radius/69.1))..(lat+(radius/69.1)),
                                                                :lon => (lon-(radius/53.0))..(lon+(radius/53.0)) },
                                                              :order => "country, state, city" } }

  named_scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  named_scope :search, lambda { |search| {:conditions => simple_search(search) } } 
  named_scope :minus_already_linked, lambda {|citation|
    if citation.nil?
      {}
    else
      { :conditions => ["id not in (?)", citation.sites.collect(&:id) ] }
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
