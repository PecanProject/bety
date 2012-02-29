class PosteriorsRuns < ActiveRecord::Base

  validates_presence_of     :posterior_id
  validates_presence_of     :run_id
  comma do
    posterior_id
    run_id
    created_at
    updated_at
  end

end
