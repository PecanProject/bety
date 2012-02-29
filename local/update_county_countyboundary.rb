
RAILS_ENV='production'
require '/rails/ebi/config/environment'

c = County.last.id - County.first.id
cc = 0
counties = County.all

counties.each do |county|
  p "#{c-cc}"
  c += 1
  CountyBoundary.find_all_by_censusid(county.censusid).each do |cb|
    p "  #{cb.id}"
    cb.county = county
    cb.save
  end
end
