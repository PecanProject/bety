class PftsPriors < ActiveRecord::Base
  validates_presence_of     :pft_id
  validates_presence_of     :prior_id
  comma do
    pft_id
    prior_id
    created_at
    updated_at
  end

end
