class PftsSpecies < ActiveRecord::Base
  self.primary_key = "id"

  belongs_to :pft
  belongs_to :specie

  validates_presence_of     :pft_id
  validates_presence_of     :specie_id
  comma do
    pft_id
    specie_id
    created_at
    updated_at
  end

end
