class Covariate < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ variable }
  SEARCH_FIELDS = %w{ variables.name covariates.level covariates.n covariates.stat covariates.statname }

  scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  scope :search, lambda { |search| {:conditions => simple_search(search) } }

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
