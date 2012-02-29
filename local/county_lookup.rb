#!/usr/bin/ruby

RAILS_ENV='production'
require '/rails/ebi/config/environment'

require 'rubygems'
require 'curl'
require 'json'

f = File.new "/rails/ebi/last_id_location_yields"
lastid = f.gets.to_i
f.close
firsttime = true

ly = LocationYield.all(:conditions => "location is null and id >= #{lastid}",:limit => 3000)

states = ["Alabama",  "Alaska",  "American Samoa",  "Arizona",  "Arkansas",  "California",  "Colorado",  "Connecticut",  "Delaware",  "District of Columbia",  "Florida",  "Georgia",  "Guam",  "Hawaii",  "Idaho",  "Illinois",  "Indiana",  "Iowa",  "Kansas",  "Kentucky",  "Louisiana",  "Maine",  "Maryland",  "Massachusetts",  "Michigan",  "Minnesota",  "Mississippi",  "Missouri",  "Montana",  "Nebraska",  "Nevada",  "New Hampshire",  "New Jersey",  "New Mexico",  "New York",  "North Carolina",  "North Dakota",  "Northern Marianas Islands",  "Ohio",  "Oklahoma",  "Oregon",  "Pennsylvania",  "Puerto Rico",  "Rhode Island",  "South Carolina",  "South Dakota",  "Tennessee",  "Texas",  "Utah",  "Vermont",  "Virginia",  "Virgin Islands",  "Washington",  "West Virginia",  "Wisconsin",  "Wyoming"]

ly.each do |_ly|
  curl = Curl::Easy.http_get("http://maps.googleapis.com/maps/api/geocode/json?latlng=#{_ly.lat},#{_ly.lon}&sensor=false")
  result = JSON.parse(curl.body_str)
  state,county,country = "","",""
  if result["status"] == "OVER_QUERY_LIMIT"
    if !firsttime
      lastid = _ly.id
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

  next if "#{county}, #{state}" == ", "
  _ly.update_attribute(:location, "#{county}, #{state}")
  _ly.update_attribute(:country, "#{country}")
  p "#{_ly.id}:#{_ly.location}"
end

f = File.new "/rails/ebi/last_id_location_yields", "w"

f.puts lastid

f.close

