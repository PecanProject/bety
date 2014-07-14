class PosteriorsEnsembles < ActiveRecord::Base

  validates_presence_of     :posterior_id
  validates_presence_of     :ensemble_id
  comma do
    posterior_id
    ensemble_id
    created_at
    updated_at
  end

end
