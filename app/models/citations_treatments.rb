class CitationsTreatments < ActiveRecord::Base
  self.primary_key = "id"

  validates_presence_of     :citation_id
  validates_presence_of     :treatment_id

  belongs_to :citation
  belongs_to :treatment

  comma do
    citation_id
    treatment_id
    created_at
    updated_at
  end
end
