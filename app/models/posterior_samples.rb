class PosteriorSamples < ActiveRecord::Base

  validates_presence_of     :posterior_id
  validates_presence_of     :variable_id
  validates_presence_of     :pft_id
  validates_presence_of     :parent_id
  
  comma do
    posterior_id
    variable_id
    pft_id
    parent_id
    created_at
    updated_at
  end

end
