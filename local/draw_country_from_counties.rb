#!/usr/bin/ruby

RAILS_ENV='production'
require '/rails/ebi/config/environment'

require 'rvg/rvg'
include Magick

def drawcountry(crop = "miscanthus")

  #cpoints = CountyBoundary.all


  totlatmax = CountyBoundary.first(:order => "lat desc") .lat.to_f
  totlatmin = CountyBoundary.first(:order => "lat asc").lat.to_f
  totlngmax = CountyBoundary.first(:order => "lng desc").lng.to_f
  totlngmin = CountyBoundary.first(:order => "lng asc").lng.to_f

  totlngdiff = (totlngmax-totlngmin).abs
  totlatdiff = (totlatmax-totlatmin).abs

  ratio = totlngdiff/totlatdiff

  #z = 100

  color_range = {}
  color_range[:max] = LocationYield.all(:conditions => ["species = ?",crop],:order => 'yield desc', :limit => 1)[0].yield.to_f
  color_range[:min] = LocationYield.all(:conditions => ["species = ?",crop],:order => 'yield asc', :limit => 1)[0].yield.to_f

  # Five Colors
  color_range[:total] = (color_range[:max] - color_range[:min])/5

  counties = County.all

  z = 1

  country = Image.new(12078,1800) { self.background_color = "transparent" }

  counties.each do |_counties|
    next if z > 10
    z += 1
    _censusids = _counties.censusid

    avg = LocationYield.find_by_sql(["select avg(yield) from location_yields where location = ? and species = ?","#{_counties.name}, #{_counties.state}",crop])[0]["avg(yield)"].to_f

    next if avg.nil?

    p _counties.name
    p _counties.state

    c = CountyBoundary.find_by_sql("select lat,lng from county_boundaries where censusid = #{_censusids}")

     c.delete_at(0)
     cc = c.collect {|x| "#{x.lng},#{x.lat}"}.join(" ")

     next if cc.length == 0

     if avg >= color_range[:total]*5
       color = 255
     elsif avg >= color_range[:total]*4
       color = 219
     elsif avg >= color_range[:total]*3
       color = 183
     elsif avg >= color_range[:total]*2
       color = 147
     else
       color = 111
     end

     countyx = totlngmin - CountyBoundary.first(:conditions => ["censusid = ?",_counties.censusid], :order => "lng asc").lng.to_f
     countyy = totlatmax - CountyBoundary.first(:conditions => ["censusid = ?",_counties.censusid], :order => "lat desc") .lat.to_f

     system( "convert /rails/ebi/counties/#{_counties.id}.png -fuzz 100% -fill 'rgba(0,#{color},0,.5)' -opaque 'rgba(0,0,0,.5)' /rails/ebi/counties/#{_counties.id}.png" )

     country.composite!(Image.read("/rails/ebi/counties/#{_counties.id}.png")[0],countyx,countyy,OverCompositeOp)

    end
  country.write("/rails/ebi/public/country3.png")
end

drawcountry(ARGV[0])
