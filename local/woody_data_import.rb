
RAILS_ENV='production'
require '/rails/ebi/config/environment'

f = File.new "woody_data_import.traits"

woody = Struct.new(:tmpid,:site_id,:specie_id,:citation_id,:cultivar_id,:treatment_id,:date,:dateloc,:time,:timeloc,:mean,:n,:statname,:stat,:notes,:created_at,:updated_at,:variable_id,:user_id,:checked,:access_level)

woodys = []

f.gets # header

f.each_line do |line|
  woodys << woody.new(*line.chomp!.split(","))
end

f.close

traits = []

woodys.each do |wood|
  t = Trait.new
  wood.members.each do |key|
    wood[key] = nil if wood[key] == "NA"
  end

  t[:site_id] = wood[:site_id].to_i if !wood[:site_id].nil?
  t[:specie_id] = wood[:specie_id].to_i if !wood[:specie_id].nil?
  t[:citation_id] = wood[:citation_id].to_i if !wood[:citation_id].nil?
  t[:cultivar_id] = wood[:cultivar_id].to_i if !wood[:cultivar_id].nil?
  t[:treatment_id] = wood[:treatment_id].to_i if !wood[:treatment_id].nil?
  t[:date] = Date.parse(wood[:date]) if !wood[:date].nil?
  t[:dateloc] = wood[:dateloc].to_f if !wood[:dateloc].nil?
  t[:time] = DateTime.parse(wood[:time]) if !wood[:time].nil?
  t[:timeloc] = wood[:timeloc].to_f if !wood[:timeloc].nil?
  t[:mean] = wood[:mean].to_f if !wood[:mean].nil?
  t[:n] = wood[:n].to_i if !wood[:n].nil?
  t[:statname] = wood[:statname] if !wood[:statname].nil?
  t[:stat] = wood[:stat].to_f if !wood[:stat].nil?
  t[:notes] = wood[:notes] if !wood[:notes].nil?
  t[:created_at] = Time.now 
  t[:updated_at] = Time.now 
  t[:variable_id] = wood[:variable_id].to_i if !wood[:variable_id].nil?
  t[:user_id] = wood[:user_id].to_i if !wood[:user_id].nil?
  t[:checked] = 0 
  t[:access_level] = wood[:access_level].to_i if !wood[:access_level].nil?


  t.save
  traits << t
end

f = File.new "woody_data_import.traits.out", "w"

f.puts traits[0].to_comma_headers.join(",")

traits.each do |trait|
  f.puts trait.to_comma.join(",")
end

f.close
