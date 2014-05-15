class Covariate < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ variable }
  SEARCH_FIELDS = %w{ variables.name covariates.level covariates.n covariates.stat covariates.statname }

  validate :level_in_range

  def level_in_range
    v = Variable.find(variable_id)
    if !v.min.nil? and level < v.min.to_f
      errors.add(:level, "The value of level for the #{v.name} trait must be at least #{v.min}.")
    end
    if !v.max.nil? and level > v.max.to_f
      errors.add(:level, "The value of level for the #{v.name} trait must be at most #{v.max}.")
    end
  end
  
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
