class Pft < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ modeltype }
  SEARCH_FIELDS = %w{ pfts.name pfts.definition modeltypes.name }

  has_many :pfts_priors, :class_name => "PftsPriors"
  has_many :priors, :through => :pfts_priors

  has_many :pfts_species, :class_name => "PftsSpecies"
  has_many :specie, :through => :pfts_species

  has_many :posteriors

  #Self reference
  has_many :children, :class_name => "Pft", :foreign_key => "parent_id"
  belongs_to :parent, :class_name => "Pft", :foreign_key => "parent_id"

  belongs_to :modeltype

  # VALIDATION

  ## Validation callbacks

  before_validation WhitespaceNormalizer.new([:name])

  ## Validations

  validates :name,
      presence: true,
      uniqueness: { scope: :modeltype_id,
                    message: "has already been used with this Model." }

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  comma do
    id
    definition
    modeltype_id
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
    return ["pfts.id", "pfts.name", "pfts.definition", "pfts.modeltype.name"]
  end
end
