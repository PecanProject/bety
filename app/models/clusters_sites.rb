class ClustersSites < ActiveRecord::Base
  self.primary_key = "id"

  belongs_to :cluster
  belongs_to :site

  validates_presence_of     :cluster_id
  validates_presence_of     :site_id
  comma do
    cluster_id
    site_id
    created_at
    updated_at
  end

end
