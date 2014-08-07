class Modeltype < ActiveRecord::Base
  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ model_types.name }

  has_many :modeltypes_formats
  has_many :models
  has_many :pfts
  belongs_to :user

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  validates_uniqueness_of :name

  comma do
    id
    name
    user_id
    created_at
    updated_at
  end

  def to_s
    name
  end

  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["modeltypes.id", "modeltypes.name"]
  end
end
