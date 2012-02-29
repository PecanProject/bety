#!/usr/bin/ruby

RAILS_ENV='production'
require '/rails/ebi/config/environment'

require 'rvg/rvg'
include Magick

def drawcountry(crop = "miscanthus")

  p crop
  p "Finished reading boundaries"

  color_range = {}
  color_range[:max] = LocationYield.all(:conditions => ["species = ?",crop],:order => 'yield desc', :limit => 1)[0].yield.to_f
  color_range[:min] = LocationYield.all(:conditions => ["species = ?",crop],:order => 'yield asc', :limit => 1)[0].yield.to_f

  color_range[:increment] = (color_range[:max] - color_range[:min])/6

  scale = File.new "/rails/ebi/public/#{crop}-scale.csv", "w"

  scale.puts "#{color_range[:min]+color_range[:increment]*1},#{color_range[:min]+color_range[:increment]*(2)},00ff00"
  scale.puts "#{color_range[:min]+color_range[:increment]*2},#{color_range[:min]+color_range[:increment]*(3)},00db00"
  scale.puts "#{color_range[:min]+color_range[:increment]*3},#{color_range[:min]+color_range[:increment]*(4)},00b700"
  scale.puts "#{color_range[:min]+color_range[:increment]*4},#{color_range[:min]+color_range[:increment]*(5)},009300"
  scale.puts "#{color_range[:min]+color_range[:increment]*5},#{color_range[:min]+color_range[:increment]*(6)},000b00"

  scale.close

  counties = County.all
  p "Rendering Counties"

  kml = File.new "/rails/ebi/public/#{crop}.kml", "w"

  kml.puts '<?xml version="1.0" encoding="UTF-8"?>'
  kml.puts '<kml xmlns="http://www.opengis.net/kml/2.2">'
  kml.puts "<Folder>"
  kml.puts "<name>#{crop}</name>"
  kml.puts "<description>Overlay of #{crop} yields </description>"

  counties.each do |_counties|
    _censusids = _counties.censusid

    next if CountyBoundary.all(:conditions => ["censusid = ?",_counties.censusid]).length < 4

    countylatmax = CountyBoundary.first(:conditions => ["censusid = ?",_counties.censusid], :order => "lat desc").lat.to_f
    countylatmin = CountyBoundary.first(:conditions => ["censusid = ?",_counties.censusid], :order => "lat asc").lat.to_f
    countylngmax = CountyBoundary.first(:conditions => ["censusid = ?",_counties.censusid], :order => "lng desc").lng.to_f
    countylngmin = CountyBoundary.first(:conditions => ["censusid = ?",_counties.censusid], :order => "lng asc").lng.to_f

    countylngdiff = (countylngmax-countylngmin).abs
    countylatdiff = (countylatmax-countylatmin).abs

    ratio = countylngdiff/countylatdiff
    
    p countylngmin
    p countylatmin
    p countylngdiff
    p countylatdiff
    p ratio
    RVG::dpi = 900
    rvg = RVG.new((1*ratio).in, 1.in).viewbox(countylngmin,countylatmin,countylngdiff,countylatdiff) do |canvas|
      canvas.background_fill_opacity = 0.0

      avg = LocationYield.find_by_sql(["select avg(yield) from location_yields where location = ? and species = ?","#{_counties.name},#{_counties.state}",crop])[0]["avg(yield)"]

      #next if avg.nil?
      avg = 0.0 if avg.nil?

      p _counties.name
      p _counties.state
      p _counties.id

      c = CountyBoundary.find_by_sql("select lat,lng from county_boundaries where censusid = #{_censusids}") 

      c.delete_at(0)
      cc = c.collect {|x| "#{x.lng},#{x.lat}"}.join(" ")
      
      next if cc.length == 0

      if avg == 0.0
        color = "rgb(250,0,0)"
      elsif avg >= color_range[:min]+color_range[:increment]*5
        color = "rgb(0,255,0)"
      elsif avg >= color_range[:min]+color_range[:increment]*4
        color = "rgb(0,219,0)"
      elsif avg >= color_range[:min]+color_range[:increment]*3
        color = "rgb(0,183,0)"
      elsif avg >= color_range[:min]+color_range[:increment]*2
        color = "rgb(0,147,0)"
      else
        color = "rgb(0,111,0)"
      end

      county = RVG::Group.new do |_county|
        #_county.path("M #{cc} Z").styles(:stroke_width => 0, :fill_opacity => 0.5, :fill => "rgb(0,#{color},0)")
        _county.path("M #{cc} Z").styles(:stroke_width => 0, :fill_opacity => 0.5, :fill => "#{color}")
      end
      canvas.use(county)
    end

    kml.puts "    <GroundOverlay>"
    kml.puts "      <name>#{_counties.name}, #{_counties.state}</name>"
#    kml.puts "      <description>#{_counties.id}</description>"
    kml.puts "      <Icon>"
    kml.puts "        <href>/bety/location_yields/#{crop}/#{_counties.id}.png</href>"
    kml.puts "      </Icon>"
    kml.puts "      <LatLonBox>"
    kml.puts "        <north>#{countylatmax}</north>"
    kml.puts "        <south>#{countylatmin}</south>"
    kml.puts "        <east>#{countylngmax}</east>"
    kml.puts "        <west>#{countylngmin}</west>"
    kml.puts "      </LatLonBox>"
    kml.puts "    </GroundOverlay>"
    rvg.draw.write("/rails/ebi/public/location_yields/#{crop}/#{_counties.id}.png")
    system( "convert /rails/ebi/public/location_yields/#{crop}/#{_counties.id}.png -flip /rails/ebi/public/location_yields/#{crop}/#{_counties.id}.png" )
  end
  kml.puts "  </Folder>"
  kml.puts "</kml>"
  kml.close
end

drawcountry(ARGV[0])
