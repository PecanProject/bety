class County < ActiveRecord::Base
  has_many :county_boundaries
  has_many :county_paths
  has_many :location_yields
end
