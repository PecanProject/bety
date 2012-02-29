#Should be run from rails console...

require 'csv'

county = Struct.new :objectid,:join_count,:target_fid,:name,:state_name,:state_fips,:county_fips,:fips,:loc,:lat,:lon,:sgyield
counties = []

CSV.open('/rails/ebi/local/pavi02212012.csv','r') do |row|

  counties << county.new(*row)

end

counties.delete_at(0) # Remove header

problem_lines = []

puts "state_fips,county_fips,length"
counties.each do |c|

  dbc = County.all(:conditions => ["state_fips = ? and county_fips = ?",c.state_fips,c.county_fips])

  if dbc.length == 0
    problem_lines << "#{c.state_fips},#{c.county_fips},#{dbc.length}"
    next
  end

  dbc.each do |_dbc|

    ly = LocationYield.new

    ly.species = "switchgrass"
    ly.yield = c.sgyield.to_f
    ly.county = _dbc

    ly.save
  end

end


