class Model < ActiveRecord::Base
  attr_protected []

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ modeltype }
  SEARCH_FIELDS = %w{ models.model_name models.revision modeltypes.name }

  has_many :files, :as => :container, :class_name => 'DBFile'
  has_many :runs
  belongs_to :modeltype
  has_many :children, :class_name => "Model", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Model"


  # VALIDATION

  ## Validation callbacks

  before_validation WhitespaceNormalizer.new([:revision])

  ## Validations

  validates_presence_of :modeltype_id
  validates_format_of :model_name, with: /\A\S*\z/, message: "can't contain whitespace"


  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES).references(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  comma do
    id
    revision
    modeltype_id
    parent_id
    created_at
    updated_at
  end

  def modelname_revision
    "#{modeltype.name} #{revision}"
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
    return ["models.id", "models.modeltype.name", "models.revision"]
  end
end
