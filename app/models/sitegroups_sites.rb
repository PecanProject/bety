class SitegroupsSites < ActiveRecord::Base
  self.primary_key = "id"

  belongs_to :sitegroup
  belongs_to :site

  validates_presence_of     :sitesgroup_id
  validates_presence_of     :site_id

  comma do
    sitegroup_id
    site_id
    created_at
    updated_at
  end

end
