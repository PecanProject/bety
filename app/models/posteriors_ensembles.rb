class PosteriorsEnsembles < ActiveRecord::Base

  belongs_to :ensemble
  belongs_to :posterior

  validates_presence_of     :posterior_id
  validates_presence_of     :ensemble_id
  comma do
    posterior_id
    ensemble_id
    created_at
    updated_at
  end

end
