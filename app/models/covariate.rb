class Covariate < ActiveRecord::Base
  attr_protected []

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ variable }
  SEARCH_FIELDS = %w{ variables.name covariates.level covariates.n covariates.stat covariates.statname }



  # Validations

  ## Validation methods

  def level_in_range
    v = Variable.find(variable_id)
    if v.min != "-Infinity" and level < v.min.to_f
      errors.add(:level, "The value of level for the #{v.name} trait must be at least #{v.min}.")
    end
    if v.max != "Infinity" and level > v.max.to_f
      errors.add(:level, "The value of level for the #{v.name} trait must be at most #{v.max}.")
    end
  end

  ## Validation callbacks

  before_validation StatnameCallbacks.new

  ## Validations

  validates_numericality_of :level
  validate :level_in_range
  validates :n,
      numericality: { only_integer: true,
                      greater_than_or_equal_to: 1 },
      unless: Proc.new { |a| a.n.blank? }
  validates_numericality_of :stat, unless: Proc.new { |a| a.stat.blank? }



  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  belongs_to :trait
  belongs_to :variable

  comma do
    id
    trait_id
    variable_id
    level
    created_at
    updated_at
  end
end
