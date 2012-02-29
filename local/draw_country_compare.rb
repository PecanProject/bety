
#require 'rubygems'

#require '/home/mulroony/ruby/rubygems-1.3.5/bin/gem'

RAILS_ENV='production'
require '/rails/ebi/config/environment'

require 'rvg/rvg'
include Magick

def drawcountry(crop = "miscanthus")

  time = Time.now

  p crop
  p "Finished reading boundaries"

  totlatmax = CountyBoundary.first(:order => "lat desc") .lat.to_f
  totlatmin = CountyBoundary.first(:order => "lat asc").lat.to_f
  totlngmax = CountyBoundary.first(:order => "lng desc").lng.to_f
  totlngmin = CountyBoundary.first(:order => "lng asc").lng.to_f

  totlngdiff = (totlngmax-totlngmin).abs
  totlatdiff = (totlatmax-totlatmin).abs

  ratio = totlngdiff/totlatdiff

  color_range = {}
  color_range[:max] = LocationYield.all(:conditions => ["species = ?",crop],:order => 'yield desc', :limit => 1)[0].yield.to_f
  color_range[:min] = LocationYield.all(:conditions => ["species = ?",crop],:order => 'yield asc', :limit => 1)[0].yield.to_f

  # Five Colors
  color_range[:increment] = (color_range[:max] - color_range[:min])/5

  scale = File.new "/rails/ebi/public/#{crop}-scale.csv", "w"
                                                                                                                      #255,0,0
  scale.puts "#{color_range[:min]+color_range[:increment]*0},#{color_range[:min]+color_range[:increment]*(1)},6f0000" #111,0,0
  scale.puts "#{color_range[:min]+color_range[:increment]*1},#{color_range[:min]+color_range[:increment]*(2)},00ff00" #0,255,0
  scale.puts "#{color_range[:min]+color_range[:increment]*2},#{color_range[:min]+color_range[:increment]*(3)},006f00" #0,111,0
  scale.puts "#{color_range[:min]+color_range[:increment]*3},#{color_range[:min]+color_range[:increment]*(4)},0000ff" #0,0,255
  scale.puts "#{color_range[:min]+color_range[:increment]*4},#{color_range[:min]+color_range[:increment]*(5)},00006f" #0,0,111

  scale.close

  counties = County.all
  p "Finished collecting censusid's"

  RVG::dpi = 900
  rvg = RVG.new((2*ratio).in, 2.in).viewbox(totlngmin,totlatmin,totlngdiff,totlatdiff) do |canvas|
    canvas.background_fill_opacity = 0.0

    counties.each do |_counties|
      _censusids = _counties.censusid

      avg = LocationYield.find_by_sql(["select avg(yield) from location_yields where location = ? and species = ?","#{_counties.name}, #{_counties.state}",crop])[0]["avg(yield)"].to_f

      avg = 0.0 if avg.nil?

      #p _counties.name
      #p _counties.state

      c = CountyBoundary.find_by_sql("select lat,lng from county_boundaries where censusid = #{_censusids}")

      c.delete_at(0)
      cc = c.collect {|x| "#{x.lng},#{x.lat}"}.join(" ")

      next if cc.length == 0

      if avg == 0.0
        color = "rgb(255,0,0)"
      elsif avg >= color_range[:min]+color_range[:increment]*4
        color = "rgb(0,0,111)"
      elsif avg >= color_range[:min]+color_range[:increment]*3
        color = "rgb(0,0,255)"
      elsif avg >= color_range[:min]+color_range[:increment]*2
        color = "rgb(0,111,0)"
      elsif avg >= color_range[:min]+color_range[:increment]*1
        color = "rgb(0,255,0)"
      else
        color = "rgb(111,0,0)"
      end
      #p color

      #p "#{_counties.name} : #{avg}" if avg != 0.0

      county = RVG::Group.new do |_county|
        #_county.path("M #{cc} Z").styles(:fill_opacity => 0.5, :fill => "#{color}")
        _county.path("M #{cc} Z").styles(:stroke_width => 0.0000000001, :fill_opacity => 0.5, :fill => "#{color}", :stroke_opacity => 0.0, :stroke => "#{color}")
      end
      canvas.use(county)
    end
  end
  rvg.draw.write("/rails/ebi/public/#{crop}.png")
  system( "convert /rails/ebi/public/#{crop}.png -flip /rails/ebi/public/#{crop}.png" )

  p "#{(Time.now - time).to_f}"
end

plant = ARGV[0]

if plant == "all"
  drawcountry("miscanthus")
  drawcountry("switchgrass")
  drawcountry("poplar")
else
  drawcountry(plant)
end
