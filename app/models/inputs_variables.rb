class InputsVariables < ActiveRecord::Base
  validates_presence_of     :input_id
  validates_presence_of     :variable_id
  comma do
    input_id
    variable_id
    created_at
    updated_at
  end
end
