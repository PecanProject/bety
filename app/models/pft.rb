class Pft < ActiveRecord::Base

  include Overrides
  include Cloner

  extend SimpleSearch
  SEARCH_INCLUDES = %w{  }
  SEARCH_FIELDS = %w{ pfts.name pfts.definition }

  has_and_belongs_to_many :priors
  has_and_belongs_to_many :specie
  has_many :posteriors

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  comma do
    id
    definition
    created_at
    updated_at
    name
  end

  def name_definition
    "#{name} #{definition[0..19]}"
  end
  def to_s
    name_definition
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["pfts.id", "pfts.name", "pfts.definition"]
  end
end
