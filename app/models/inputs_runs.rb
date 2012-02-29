class InputsRuns < ActiveRecord::Base
  validates_presence_of     :input_id
  validates_presence_of     :run_id
  comma do
    input_id
    run_id
    created_at
    updated_at
  end
end
