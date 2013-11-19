RAILS_ENV='production'
require '../config/environment'

f = File.new "woody_data_import.traits"

Woody = Struct.new(:tmpid,:site_id,:specie_id,:citation_id,:cultivar_id,
                   :treatment_id,:date,:dateloc,:time,:timeloc,:mean,:n,
                   :statname,:stat,:notes,:created_at,:updated_at,:variable_id,
                   :user_id,:checked,:access_level)

woodys = []

f.gets # discard the first line, assumed to be the header

f.each_line do |line|
  # Although the Ruby documentation doesn't state this explicitly, we
  # assume the arguments passed to Woody.new are assigned to
  # attributes in the order they are listed in Struct.new.
  woodys << Woody.new(*line.chomp!.split(","))
end

f.close

# This stores the Trait objects created for each row of the CSV file.
traits = []

woodys.each do |woody|
  t = Trait.new

  # Normalize all struct member values to nil if "NA" appears in the input CSV file.
  woody.members.each do |key|
    woody[key] = nil if woody[key] == "NA"
  end

  # The to_i type conversions are probably unnecessary here (they seem to have no effect).
  # The to_f type conversions may be unnecessare.  They seem only to prevent rounding.
  # The Date.parse and DateTime.parse calls are probably unnecessary as well.
  t[:site_id] = woody[:site_id].to_i if !woody[:site_id].nil?
  t[:specie_id] = woody[:specie_id].to_i if !woody[:specie_id].nil?
  t[:citation_id] = woody[:citation_id].to_i if !woody[:citation_id].nil?
  t[:cultivar_id] = woody[:cultivar_id].to_i if !woody[:cultivar_id].nil?

  t[:treatment_id] = woody[:treatment_id].to_i if !woody[:treatment_id].nil?
  t[:date] = Date.parse(woody[:date]) if !woody[:date].nil?
  t[:dateloc] = woody[:dateloc].to_f if !woody[:dateloc].nil?
  t[:time] = DateTime.parse(woody[:time]) if !woody[:time].nil?
  t[:timeloc] = woody[:timeloc].to_f if !woody[:timeloc].nil?
  t[:mean] = woody[:mean].to_f if !woody[:mean].nil?
  t[:n] = woody[:n].to_i if !woody[:n].nil?

  t[:statname] = woody[:statname] if !woody[:statname].nil?
  t[:stat] = woody[:stat].to_f if !woody[:stat].nil?
  t[:notes] = woody[:notes] if !woody[:notes].nil?
  t[:created_at] = Time.now 
  t[:updated_at] = Time.now 
  t[:variable_id] = woody[:variable_id].to_i if !woody[:variable_id].nil?

  t[:user_id] = woody[:user_id].to_i if !woody[:user_id].nil?
  t[:checked] = 0 
  t[:access_level] = woody[:access_level].to_i if !woody[:access_level].nil?


  t.save
  traits << t
end

f = File.new "woody_data_import.traits.out", "w"

f.puts traits[0].to_comma_headers.join(",")

traits.each do |trait|
  f.puts trait.to_comma.join(",")
end

f.close
