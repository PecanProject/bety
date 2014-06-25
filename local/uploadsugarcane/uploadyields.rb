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

  # variables to keep track of missing site data
  linecounter=0;
  nosites=Array.new
  
  # Finally, iterate through the rows of the csv file and insert the
  # data into the sites table
  csv.each do |row|

    # assign row data to local varibles
    (yid, citation_id, sid, specie_id, treatment_id, cid, date, dateloc,
     statname, stat, mean, n, notes, created_at, updated_at, user_id, checked,
     access_level) = row

    # If sid is specified, find the the id for the corresponding row
    # in the sites table.
    if !sid.nil?
      site_id_query.execute(sid)
      row_count = site_id_query.size
      if row_count > 1
        puts "Found multiple rows in temp_site_ids table with name = #{sid}"
        puts "Quitting."
        exit
      elsif row_count == 0
        if sid == "0"
          site_id = nil
        else
          # Assume sid is the id number of an previously existing site
          # in the sites table
          site_id = sid
        end
      else # exactly one row found
        (site_id,) = site_id_query.fetch
      end
    else
      side_id = nil
    end

    # Keep track of the rows in the csv file having no site id information
    if site_id.nil?
      nosites << linecounter;
    end

    if !cid.nil?
      cultivar_id_query.execute(cid)
      row_count = cultivar_id_query.size
      if row_count > 1
        puts "Found multiple rows in temp_cultivar_ids table with name = #{cid}"
        puts "Quitting."
        exit
      elsif row_count == 0
        if cid == "0"
          cultivar_id = nil
        elsif cid =~ /^\d+$/
          # Assume cid is the id number of an previously existing site
          # in the sites table
          cultivar_id = cid
        elsif cid == "#N/A"
          # Grudgingly allow this value
          cultivar_id = nil
        else
          # We have a non-integer cid that doesn't match anything in
          # the temp_cultivar_ids table.  Print an error and quit.

          message = <<-MESSAGE
Cultivar id value '#{cid}' is not an integer and does
not match any of the values in the temp_cultivar_ids table.
quitting
          MESSAGE

          puts message
          exit
        end
      else # exactly one row found
        (cultivar_id,) = cultivar_id_query.fetch
      end
    else
      cultivar_id = nil
    end

    if specie_id.nil?
      puts "Each row in the csv file must include a species_id"
      puts "Quitting"
      exit
    end

    puts "linecounter = #{linecounter}"
    # convert the date into an acceptible format
    if !date.nil?
      date = convert_date(date)
    end

    puts "linecounter=#{linecounter} citation_id=#{citation_id} site_id=#{site_id} specie_id=#{specie_id} treatment_id=#{treatment_id}\n"
    puts "cultivar_id=#{cultivar_id} date=#{date} dateloc= #{dateloc} statname= #{statname} stat=#{stat} mean=#{mean}\n"
    puts "n=#{n} notes=#{notes} created_at=#{created_at} updated_at=#{updated_at} user_id=#{user_id} checked =#{checked}\n"
    puts "access_level=#{access_level}\n"

    insert_statement.execute(citation_id, site_id, specie_id, treatment_id,
                             cultivar_id, date, dateloc, statname, stat, 
                             mean, n, notes, created_at, updated_at, user_id,
                             checked, access_level) 

    linecounter=linecounter+1;
  end

  puts "#{nosites.size} rows of the csv file have have no site information."

  # Clean up temporary tables
  con.query("DROP TABLE temp_site_ids")
  con.query("DROP TABLE temp_cultivar_ids")

rescue Mysql::Error => e
  puts e.errno
  puts e.error
  puts e.backtrace.join("\n")
  
ensure
  con.close if con
end
