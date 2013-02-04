class Model < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ models.model_name models.model_path models.revision }

  has_many :runs
  has_many :children, :class_name => "Model", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Model"

  validates_presence_of     :model_name

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  comma do
    id
    model_name
    model_path
    revision
    parent_id
    created_at
    updated_at
  end

  def modelname_revision
    "#{model_name} #{revision}"
  end
  def to_s
    modelname_revision
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["models.id", "models.model_name", "models.revision"]
  end
end
