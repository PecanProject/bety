require './utilities.rb'

# MAIN PROGRAM

begin

  # First get open the csv file and check the header:

  csv = CSV.open(get_input_file('sugarcanecultivars.csv'))

  # Check that the header row is what we expect
  EXPECTED_HEADER = %w(id specie_id name ecotype notes created_at updated_at
                       previous_id)
  header = csv.readline

  check_csv_header(header, EXPECTED_HEADER)


  # Now open a connection to the database:

  con = get_connection_interactively

  # Create a temporary table to keep track of the mapping between site
  # ids as listed in the csv file and the id numbers generated upon
  # inserting a site into the sites table
  create_temp_table(con, "temp_cultivar_ids")

  INSERT_STRING = <<-INSERTION
    INSERT INTO cultivars(specie_id, name, ecotype, notes, created_at, updated_at, previous_id)
		VALUES(?, ?, ?, ?, COALESCE(?, NOW()), COALESCE(?, NOW()), ?)
  INSERTION
  insert_statement = con.prepare(INSERT_STRING)

  # The query to get the generated id of site just inserted.  We assume
  # (lon, lat, sitename) form a natural key.  In particular, we assume
  # each is non-null.
  ID_QUERY_STRING = <<-SELECTION
    SELECT id FROM cultivars 
        WHERE specie_id = ? AND name = ?
  SELECTION

  id_query = con.prepare(ID_QUERY_STRING)




  # Finally, iterate through the rows of the csv file and insert the
  # data into the sites table
  csv.each do |row| 

    # assign row data to local varibles
    (id, species_id, name , ecotype, notes, 
     created_at, updated_at, previous_id) = row

    # Display to the user what data is being inserted
    puts "id = #{id}"
    puts "specie_id = #{species_id}"
    puts "name = #{name}"
    puts "ecotype = #{ecotype}"
    puts "notes = #{notes}"
    puts "created_at = #{created_at}"
    puts "updated_at = #{updated_at}"
    puts "previous_id = #{previous_id}"

    insert_statement.execute(species_id, name, ecotype, notes, created_at,
                             updated_at, previous_id)

    # Now get the automatically-generated id number
    id_query.execute(species_id, name)
    row_count = id_query.size
    # Check that we get only the id for the row we just inserted--that
    # is, (specie_id, name) should be unique
    if row_count == 0
      puts "Couldn't find a row with specie_id = #{species_id} and name = #{name}"
      puts "Quitting"
      exit
    elsif row_count > 1
      puts "Found more than one row with specie_id = #{species_id} and name = #{name}"
      puts "Quitting"
      exit
    end
    (id_number,) = id_query.fetch

    # Record the name --> id_number correspondence in the "temp_site_ids" table
    tempquery="INSERT INTO temp_cultivar_ids(name, id) VALUES('#{name}', '#{id_number}')"
    con.query(tempquery)

  end # csv.each


rescue Mysql::Error => e
  puts e.errno
  puts e.error

ensure
  con.close if con
end
