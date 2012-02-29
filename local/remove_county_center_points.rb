
RAILS_ENV='production'
require '/rails/ebi/config/environment'

counties = County.all(:include => "county_boundaries")

counties.each do |county|
  p county
  county.county_boundaries(:order => "id asc").first.delete if county.county_boundaries.length > 1
end
