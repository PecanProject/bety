#!/usr/bin/ruby

RAILS_ENV='production'
#require '/rails/ebi/config/environment'

require 'rubygems'
gem 'curb', '~> 0.7.4'
require 'curl'
require 'json'
require 'csv'

firsttime = true

class LY
  attr_accessor :loc, :lat, :lon, :sgYield, :lower, :upper, :cv, :mdep, :county, :state, :checked

  def initialize(*args)

    @loc, @lat, @lon, @sgYield, @lower, @upper, @cv, @mdep, @county, @state, @checked = args

  end

end


lys = []

CSV.open('sgYield.tsv','r', '\t') do |row| #1.8.6
#CSV.foreach('sgYield.tsv') do |row| #1.9.2

  row = row[0].split("\t")

  lys << LY.new(*row)

end

states = ["Alabama",  "Alaska",  "American Samoa",  "Arizona",  "Arkansas",  "California",  "Colorado",  "Connecticut",  "Delaware",  "District of Columbia",  "Florida",  "Georgia",  "Guam",  "Hawaii",  "Idaho",  "Illinois",  "Indiana",  "Iowa",  "Kansas",  "Kentucky",  "Louisiana",  "Maine",  "Maryland",  "Massachusetts",  "Michigan",  "Minnesota",  "Mississippi",  "Missouri",  "Montana",  "Nebraska",  "Nevada",  "New Hampshire",  "New Jersey",  "New Mexico",  "New York",  "North Carolina",  "North Dakota",  "Northern Marianas Islands",  "Ohio",  "Oklahoma",  "Oregon",  "Pennsylvania",  "Puerto Rico",  "Rhode Island",  "South Carolina",  "South Dakota",  "Tennessee",  "Texas",  "Utah",  "Vermont",  "Virginia",  "Virgin Islands",  "Washington",  "West Virginia",  "Wisconsin",  "Wyoming"]

lys.each do |_ly|
  next if !_ly.county.nil? or !_ly.state.nil? or !_ly.checked.nil?
  puts _ly.loc
  curl = Curl::Easy.http_get("http://maps.googleapis.com/maps/api/geocode/json?latlng=#{_ly.lat},#{_ly.lon}&sensor=false")
  result = JSON.parse(curl.body_str)
  state,county,country = "","",""
  puts result
  if result["status"] == "OVER_QUERY_LIMIT"
    if !firsttime
      break
    else
      system( "sleep 3" )
      firsttime = false
      redo
    end
  end
  firsttime = true
  unless result.nil? or result["results"].nil? or result["results"][0].nil? or result["results"][0]["address_components"].nil?
    result["results"].each do |i|
      if i["types"].include?("administrative_area_level_2")
        #p i
        i["address_components"].each do |_result|
          state = _result["long_name"] if _result["types"].include?("administrative_area_level_1")
          county = _result["long_name"] if _result["types"].include?("administrative_area_level_2")
          country = _result["short_name"] if _result["types"].include?("country")
        end
      end
    end
  end

  if "#{county}, #{state}" == ", "
    _ly.checked = 1
    next
  end

  _ly.county = county
  _ly.checked = 1
  _ly.state = state
end

system( 'mv sgYield.tsv sgYield.tsv.old' )

f = File.new "sgYield.tsv", "w"

lys.each do |r|
  f.puts "#{ r.loc }\t#{ r.lat }\t#{ r.lon }\t#{ r.sgYield }\t#{ r.lower }\t#{ r.upper }\t#{ r.cv }\t#{ r.mdep }\t#{ r.county }\t#{ r.state }\t#{ r.checked }"
end

f.close
