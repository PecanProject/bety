require './utilities.rb'

# MAIN PROGRAM

begin

  # First get open the csv file and check the header:


  csv = CSV.open(get_input_file("sugarcaneyields.csv"))

  # Check that the header row is what we expect
  EXPECTED_HEADER = %w(id citation_id site_id specie_id treatment_id
                       cultivar_id date dateloc statname stat mean n notes
                       created_at updated_at user_id checked access_level)
  header = csv.readline

  check_csv_header(header, EXPECTED_HEADER)


  # Now open a connection to the database:

  con = get_connection_interactively

  INSERT_STRING = <<-INSERTION
    INSERT INTO yields(citation_id, site_id, specie_id, treatment_id,
                       cultivar_id, date, dateloc, statname, stat, mean, n,
                       notes, created_at, updated_at, user_id, checked,
                       access_level) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                COALESCE(?, NOW()), COALESCE(?, NOW()), ?, ?, ?)
  INSERTION
  insert_statement = con.prepare(INSERT_STRING)

  SITE_ID_QUERY_STRING = "SELECT id FROM temp_site_ids WHERE name = ?"
  site_id_query = con.prepare(SITE_ID_QUERY_STRING)

  CULTIVAR_ID_QUERY_STRING = "SELECT id FROM temp_cultivar_ids WHERE name = ?"
  cultivar_id_query = con.prepare(CULTIVAR_ID_QUERY_STRING)

  linecounter=0;
  nosites=Array.new
  nositescounter=0;
  
  # Finally, iterate through the rows of the csv file and insert the
  # data into the sites table
  csv.each do |row|

    # assign row data to local varibles
    (yid, citation_id, sid, specie_id, treatment_id, cid, date, dateloc,
     statname, stat, mean, n, notes, created_at, updated_at, user_id, checked,
     access_level) = row

    if !sid.nil?
      site_id_query.execute(sid)
      site_id = (site_id_query.fetch)[0]
    end

    if !cid.nil?
      cultivar_id_query.execute(cid)
      result = cultivar_id_query.fetch
      if result.nil?
        puts "Couldn't find cultivar_id corresponding to #{cid}"
        exit
      end
      cultivar_id = result[0]
    end

    if site_id.nil?
      nosites[nositescounter]=linecounter;
      nositescounter=nositescounter+1
    end

    if specie_id.nil?
      puts "finished\n"
      break
    end

    # ???
    if (date=='8/1/01')
      date='08/01/2001'
    end

    puts "linecounter=#{linecounter} citation_id=#{citation_id} site_id=#{site_id} specie_id=#{specie_id} treatment_id=#{treatment_id}\n"
    puts "cultivar_id=#{cultivar_id} date=#{date} dateloc= #{dateloc} statname= #{statname} stat=#{stat} mean=#{mean}\n"
    puts "n=#{n} notes=#{notes} created_at=#{created_at} updated_at=#{updated_at} user_id=#{user_id} checked =#{checked}\n"
    puts "access_level=#{access_level}\n"
    
    date=nil;

    insert_statement.execute(citation_id, site_id, specie_id, treatment_id,
                             cultivar_id, date, dateloc, statname, stat, 
                             mean, n, notes, created_at, updated_at, user_id,
                             checked, access_level) 
      


    linecounter=linecounter+1;
end
puts "the following entries have no site\n" 
puts nosites
con.query("DROP TABLE temp")
con.query("DROP TABLE tempcultivar")
  

rescue Mysql::Error => e
  puts e.errno
  puts e.error
  
ensure
  con.close if con
end
    
    
