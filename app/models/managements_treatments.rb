class ManagementsTreatments < ActiveRecord::Base
  validates_presence_of     :management_id
  validates_presence_of     :treatment_id

  comma do
    treatment_id
    management_id
    created_at
    updated_at
  end
end
