
RAILS_ENV='production'
require '/rails/ebi/config/environment'

zo = ARGV[0].to_i


0.upto(zo) do |zoom|
  #cb_last = CountyBoundary.last(:conditions => "zoom#{zoom} is null").id
  #cb_first = CountyBoundary.first(:conditions => "zoom#{zoom} is null").id
  range = {}

  ignore_counties = County.all(:select => "id", :conditions => "state = 'Alaska' or state = 'Hawaii'").collect(&:id)

  range[:maxx] = CountyBoundary.first(:conditions => ["county_id not in ?",ignore_counties], :order => "zoom#{zoom}x desc")["zoom#{zoom}x"]
  range[:minx] = CountyBoundary.first(:conditions => ["county_id not in ?",ignore_counties], :order => "zoom#{zoom}x asc")["zoom#{zoom}x"]
  range[:maxy] = CountyBoundary.first(:conditions => ["county_id not in ?",ignore_counties], :order => "zoom#{zoom}y desc")["zoom#{zoom}y"]
  range[:miny] = CountyBoundary.first(:conditions => ["county_id not in ?",ignore_counties], :order => "zoom#{zoom}y asc")["zoom#{zoom}y"]

  crop = 'miscanthus'
  0.upto(2**zoom-1) do |tmpx|
    0.upto(2**zoom-1) do |tmpy|
  
    paramx = 256*tmpx
    paramy = 256*tmpy
 
    tile_dir = "/rails/ebi/public/maps/mapoverlay/#{crop}"
    tile_file = "/rails/ebi/public/maps/mapoverlay/#{crop}/#{tmpx}-#{tmpy}-#{zoom}.png"
 
  Dir.mkdir(tile_dir) if !File.directory?(tile_dir)



  cb_last = CountyBoundary.last.id
  cb_first = CountyBoundary.first.id
  
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
#end
