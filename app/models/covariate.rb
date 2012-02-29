class Covariate < ActiveRecord::Base
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
