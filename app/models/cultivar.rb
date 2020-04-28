class Cultivar < ActiveRecord::Base
  attr_protected []

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ specie }
  SEARCH_FIELDS = %w{ species.scientificname cultivars.previous_id cultivars.name cultivars.ecotype cultivars.notes }

  has_many :sites_cultivars, :class_name => "SitesCultivars"
  has_many :sites, :through => :sites_cultivars
  
  has_many :traits
  has_many :yields
  
  belongs_to :specie

  validates :name,
      presence: true,
      uniqueness: { scope: :specie_id,
                    message: "has already been used for this species." }
  validates_presence_of :specie_id

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES).references(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  comma do
    id
    specie_id
    name
    ecotype
    notes
    created_at
    updated_at
    previous_id
  end

  def sn_name
    "#{specie} #{name}"
  end
  def to_s
    sn_name
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["cultivars.name"]
  end
end
