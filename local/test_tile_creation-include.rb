RAILS_ENV='production'
require '/rails/ebi/config/environment'

    #Check our params, fallback to defaults if necessary
    crop = "miscanthus"
    tmpx,tmpy,zoom = 0,0,0
    crop = "miscanthus" if !["miscanthus","poplar","switchgrass"].include?( crop )
    ((1...11) === zoom.to_i) ? (zoom = zoom.to_i) : (zoom = 0)
    /^[\d]+/ === tmpx ? (tmpx = tmpx.to_i) : (tmpx = 0)
    /^[\d]+/ === tmpy ? (tmpy = tmpy.to_i) : (tmpy = 0)
    paramx = 256*tmpx
    paramy = 256*tmpy
    p "tmpx   : #{tmpx}"
    p "tmpy   : #{tmpy}"
    p "paramx : #{paramx}"
    p "paramy : #{paramy}"

    tile_dir = "/rails/ebi/public/maps/mapoverlay/#{crop}"
    tile_file = "/rails/ebi/public/maps/mapoverlay/#{crop}/#{tmpx}-#{tmpy}-#{zoom}.png"

    Dir.mkdir(tile_dir) if !File.directory?(tile_dir)
    
    merc = MercatorProjection.new(zoom)

    #PASTE
  
    color_range = {}
    color_range[:max] = LocationYield.first(:order => 'yield desc', :conditions => ["species = ?",crop]).yield.to_f
    color_range[:min] = LocationYield.first(:order => 'yield asc', :conditions => ["species = ?",crop]).yield.to_f
  
    # 120 Colors
    color_range[:increment] = (color_range[:max] - color_range[:min])/120
 
    rvg = RVG.new(256,256).viewbox(paramx,paramy,256,256) do |canvas|

      canvas.background_fill_opacity = 0.0

      # If any point of the county is in the square include iti the county
      #countyids = CountyBoundary.all(:conditions => ["(zoom#{zoom}x <= ? and zoom#{zoom}x >= ?) and (zoom#{zoom}y <= ? and zoom#{zoom}y >= ?)",paramx+256,paramx,paramy+256,paramy], :include => { :county => :county_boundaries}).collect { |x| x.county }
      tt = Time.now
      counties = County.all(:include => [:county_boundaries, :location_yields],:conditions => ["county_boundaries.zoom#{zoom}x <= ? and county_boundaries.zoom#{zoom}x >= ? and county_boundaries.zoom#{zoom}y <= ? and county_boundaries.zoom#{zoom}y >= ? and location_yields.species = ? and county_boundaries.zoom#{zoom}skip = ?",paramx+256,paramx,paramy+256,paramy,crop,false])
      p "#{(Time.now - tt).to_f} countyids"

      if counties.length > 0
        counties.each do |county|
          p "county.id : #{county}"
          p "#{(Time.now - tt).to_f} county.id"
          
          #avg = county.location_yields(:conditions => ["species = ?",crop]).yield.to_f rescue 0.0
          # Should only have one location_yield.yield per county per species
          avg = county.location_yields[0].yield.to_f rescue 0.0
  
          if avg == 0.0
            color = "hsl(0,100,100)"
          else
            tmp = ((120*avg.to_f)/color_range[:max]).round(0)
            color = "hsl(#{240+tmp.to_i},100,50)"
          end
  
          # At low enough zoom levels many of the counties are a single pixel
          # Could use RVG::Group by setting stroke_width to 1, but that might mess with
          # higher zoom levels 
          if county.county_boundaries.length == 1
            canvas.g do |_canvas|
             # p "circ: #{county.id}"
              _canvas.circle(1,county.county_boundaries[0]["zoom#{zoom}x"],county.county_boundaries[0]["zoom#{zoom}y"]).styles(:fill=>"#{color}")
            end
          else
  
            cc = county.county_boundaries.collect { |cb| cb["zoom#{zoom}x"].to_s + "," + cb["zoom#{zoom}y"].to_s }.join(" ")
            canvas.g do |_canvas|
             # p "path: #{cc}"
              _canvas.path("M #{cc}Z").styles(:stroke_width => 0.0000000001, :fill_opacity => 0.5, :fill => "#{color}", :stroke_opacity => 0.0, :stroke => "#{color}")
            end
  
          end
          p "#{(Time.now - tt).to_f} end"
        end
      else
        p "else"
      end
    end

    img = rvg.draw
    img.write(tile_file)

    #PASTE-END


