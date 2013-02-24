class Cultivar < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ specie }
  SEARCH_FIELDS = %w{ species.scientificname cultivars.previous_id cultivars.name cultivars.ecotype cultivars.notes }

  has_many :traits
  has_many :yields

  belongs_to :specie

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
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
