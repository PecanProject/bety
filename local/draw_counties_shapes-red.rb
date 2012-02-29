#!/usr/bin/ruby

RAILS_ENV='production'
require '/rails/ebi/config/environment'

require 'rvg/rvg'
include Magick

def drawcountry()

  counties = County.all

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

      p _counties.name
      p _counties.state
      p _counties.id

      c = CountyBoundary.find_by_sql("select lat,lng from county_boundaries where censusid = #{_censusids}") 

      c.delete_at(0)
      cc = c.collect {|x| "#{x.lng},#{x.lat}"}.join(" ")
      
      next if cc.length == 0

      county = RVG::Group.new do |_county|
        _county.path("M #{cc} Z").styles(:stroke_width => 0, :fill_opacity => 0.5, :fill => "rgb(255,0,0)")
      end
      canvas.use(county)
    end

    rvg.draw.write("/rails/ebi/counties/#{_counties.id}.png")
    system( "convert /rails/ebi/counties/#{_counties.id}.png -flip /rails/ebi/counties/#{_counties.id}.png" )
  end
end

drawcountry()
