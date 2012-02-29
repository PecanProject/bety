
RAILS_ENV='production'
require '/rails/ebi/config/environment'

require 'rvg/rvg'
include Magick

county = ARGV[0].to_i


0.upto(11) do |zoom|
  if zoom == 0
    conditions = "county_boundaries.zoom0skip = 0"
  elsif zoom == 1
    conditions = "county_boundaries.zoom1skip = 0"
  else
    conditions = "1 = 1"
  end

  p zoom

  #County.first.id.upto(County.last.id) do |c|
    #next if !county.blank? and c != county
    c = county

    path = CountyPath.new

    county = County.find(c,:include => :county_boundaries, :conditions => conditions) rescue next

#    next if ["Alaska", "Hawaii"].include?(county.state)
    #County.find(c,:include => :county_boundaries, :conditions => conditions).each do |county|

      path.zoom = zoom
      path.path = county.county_boundaries.collect { |cb| cb["zoom#{zoom}x"].round(4).to_s + "," + cb["zoom#{zoom}y"].round(4).to_s }.join(" ")
      path.save

      county.county_paths << path

      p county.id if county.id % 100 == 0
    #end
  #end

end

