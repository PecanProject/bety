class SitesCultivars < ActiveRecord::Base
  self.primary_key = "id"

  validates_presence_of     :cultivar_id
  validates_presence_of     :site_id

  belongs_to :cultivar
  belongs_to :site

  comma do
    cultivar_id
    site_id
    created_at
    updated_at
  end
end
