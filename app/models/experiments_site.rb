class ExperimentsSite < ActiveRecord::Base

  self.primary_key = "id"

  belongs_to :experiment
  belongs_to :site
end
