class ManagementsTreatments < ActiveRecord::Base
  self.primary_key = "id"

  validates_presence_of     :management_id
  validates_presence_of     :treatment_id

  belongs_to :management
  belongs_to :treatment

  comma do
    treatment_id
    management_id
    created_at
    updated_at
  end
end
