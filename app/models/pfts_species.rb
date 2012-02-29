class PftsSpecies < ActiveRecord::Base
  validates_presence_of     :pft_id
  validates_presence_of     :specie_id
  comma do
    pft_id
    specie_id
    created_at
    updated_at
  end

end
