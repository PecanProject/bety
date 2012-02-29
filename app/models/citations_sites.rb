class CitationsSites < ActiveRecord::Base
  validates_presence_of     :citation_id
  validates_presence_of     :site_id
  comma do
    citation_id
    site_id
    created_at
    updated_at
  end
end
