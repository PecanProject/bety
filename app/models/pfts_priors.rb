class PftsPriors < ActiveRecord::Base
  self.primary_key = "id"

  belongs_to :pft
  belongs_to :prior

  validates_presence_of     :pft_id
  validates_presence_of     :prior_id
  comma do
    pft_id
    prior_id
    created_at
    updated_at
  end

end
