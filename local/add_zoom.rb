
RAILS_ENV='production'
require '/rails/ebi/config/environment'

#zoom = ARGV[0].to_i
#county = ARGV[0].to_i


0.upto(11) do |zoom|
  cb_last = CountyBoundary.last(:conditions => "zoom#{zoom}x is null").id
  cb_first = CountyBoundary.first(:conditions => "zoom#{zoom}x is null").id
  #cb_last = County.find(county).county_boundaries.last.id
  #cb_first = County.find(county).county_boundaries.first.id
  
  merc = MercatorProjection.new(zoom,zoom)
  
  c_last_id = 0
  c_lastx = 0
  c_lasty = 0
  
  cb_first.upto(cb_last) do |cb|
    c = CountyBoundary.find(cb) rescue nil
  
    next if c.nil?
    #next if !c["zoom#{zoom}x"].nil?
  
    tmpx = merc.lng_to_pixel(c.lng)
    tmpy = merc.lat_to_pixel(c.lat)
    c["zoom#{zoom}x"] = tmpx
    c["zoom#{zoom}y"] = tmpy
    if zoom < 2
      if c_lastx == tmpx and c_lasty == tmpy and c_last_id == c.county_id 
        c["zoom#{zoom}skip"] = 1
      else
        c["zoom#{zoom}skip"] = 0
      end
    end
    c_last_id = c.county_id
    c_lastx = tmpx
    c_lasty = tmpy
   
    p "#{zoom}: #{cb_last - cb} - #{tmpx},#{tmpy}"
    c.save
  end
end
