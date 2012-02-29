#!/usr/bin/ruby

RAILS_ENV='production'
require '/rails/ebi/config/environment'

file = ARGV[0]

file = "/home/dlebauer/dev/multimodel/maps/mapdata.csv" if file.blank?

f = File.open file

data = Struct.new(:id,:other,:state_fips,:county_fips,:miscanthus,:switchgrass,:poplar,:miscanthus_poplar,:miscanthus_switchgrass,:switchgrass_poplar)

first_line = f.gets.chomp
first_line_count = first_line.split(",").length

puts "First line of : #{file}"
puts first_line
puts 
puts "Expected order :"
puts "ignored, ignored, state_fips, county_fips, miscanthus yield, switchgrass yield, poplar yield, miscanthus - poplar, miscanthus - switchgrass, switchgrass - poplar"
puts
if first_line_count != 10
  puts "Script expects 10 columns : file had #{first_line_count} columns"
  exit
else
  print "Continue? [y/n] "
  answer = gets
  answer.chomp!
  puts
  exit unless /^y/i.match( answer )
end

records = []

f.each_line do |line|
  records << data.new(*line.chomp.split(","))
end

count_updated = 0
count_new = 0
count_same = 0

records.each do |record|
  #county = County.first(:conditions => ["state_fips = ? and county_fips = ?",record.state_fips,record.county_fips])
  ccounty = County.all(:conditions => ["state_fips = ? and county_fips = ?",record.state_fips,record.county_fips])

  if ccounty.length == 0
    puts
    puts "File row that does not have county association!"
    puts "-----"
    puts record.to_yaml  
    puts "-----END"
    next
  end
  
  ccounty.each do |county|
    if miscanthus = county.location_yields.find_by_species("miscanthus")
      miscanthus.yield.to_f == record.miscanthus.to_f ? count_same += 1 : count_updated += 1
      miscanthus.yield = record.miscanthus
    else
      count_new += 1
      miscanthus = LocationYield.new(:species => "miscanthus", :yield => record.miscanthus)
    end
    miscanthus.save

    if switchgrass = county.location_yields.find_by_species("switchgrass")
      switchgrass.yield.to_f == record.switchgrass.to_f ? count_same += 1 : count_updated += 1
      switchgrass.yield = record.switchgrass
    else
      count_new += 1
      switchgrass = LocationYield.new(:species => "switchgrass", :yield => record.switchgrass)
    end
    switchgrass.save

    if poplar = county.location_yields.find_by_species("poplar")
      poplar.yield.to_f == record.poplar.to_f ? count_same += 1 : count_updated += 1
      poplar.yield = record.poplar
    else
      count_new += 1
      poplar = LocationYield.new(:species => "poplar", :yield => record.poplar)
    end
    poplar.save

    if miscanthus_poplar = county.location_yields.find_by_species("miscanthus_poplar")
      miscanthus_poplar.yield.to_f == record.miscanthus_poplar.to_f ? count_same += 1 : count_updated += 1
      miscanthus_poplar.yield = record.miscanthus_poplar
    else
      count_new += 1
      miscanthus_poplar = LocationYield.new(:species => "miscanthus_poplar", :yield => record.miscanthus_poplar)
    end
    miscanthus_poplar.save

    if miscanthus_switchgrass = county.location_yields.find_by_species("miscanthus_switchgrass")
      miscanthus_switchgrass.yield.to_f == record.miscanthus_switchgrass.to_f ? count_same += 1 : count_updated += 1
      miscanthus_switchgrass.yield = record.miscanthus_switchgrass
    else
      count_new += 1
      miscanthus_switchgrass = LocationYield.new(:species => "miscanthus_switchgrass", :yield => record.miscanthus_switchgrass)
    end
    miscanthus_switchgrass.save

    if switchgrass_poplar = county.location_yields.find_by_species("switchgrass_poplar")
      switchgrass_poplar.yield.to_f == record.switchgrass_poplar.to_f ? count_same += 1 : count_updated += 1
      switchgrass_poplar.yield = record.switchgrass_poplar
    else
      count_new += 1
      switchgrass_poplar = LocationYield.new(:species => "switchgrass_poplar", :yield => record.switchgrass_poplar)
    end
    switchgrass_poplar.save

 
    county.location_yields << miscanthus
    county.location_yields << switchgrass
    county.location_yields << poplar
    county.location_yields << miscanthus_poplar
    county.location_yields << miscanthus_switchgrass
    county.location_yields << switchgrass_poplar
  end
end

puts "Count new     : #{count_new}"
puts "Count updated : #{count_updated}"
puts "Count same    : #{count_same}"
puts "We need to create tile cache!"
puts "Do it now? [y/n] (Takes several hours!)"
answer = gets
answer.chomp!
puts
t = Time.now
system( "/usr/bin/ruby /rails/ebi/local/make_tile_cache.rb ") if /^y/i.match( answer )
puts "Making tiles took : #{(Time.now-t).to_f}"

