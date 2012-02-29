class CitationsTreatments < ActiveRecord::Base
  validates_presence_of     :citation_id
  validates_presence_of     :treatment_id
  comma do
    citation_id
    treatment_id
    created_at
    updated_at
  end
end
