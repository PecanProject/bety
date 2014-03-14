# Inserts rows into the traits table corresponding to data in the given CSV.
#
# The input file name, database host, database credentials (username
# and password), and database name are gotten interactively with
# suitable defaults.
#
# The script checks that the header row of the input file has the
# expected column names and that all species names in the input file
# correspond to exactly one row in the species table of the database
# before allowing any data to be inserted into the database.
#
# Four column values are fixed values:
#     citation_id = 738
#     user_id = 2 # dlebauer
#     checked = 0
#     access_level = 4
# (A more robust script might ask the user to confirm the values to be
# used for citation_id and user_id after displaying the data in the
# database that corresponds to these values.)


# provides get_input_file, get_connection_interactively, and check_csv_header:
require '../uploadsugarcane/utilities.rb'

# MAIN PROGRAM

species_scientificname, variable_id, site_id, date, dateloc, n, mean, stat = 
  0, 0, 0, 0, 0, 0, 0, 0


begin # trap all MySQL errors

  # Get the input file:
  input_file = get_input_file("pisek2013lia_v3.csv")

  # Now open a connection to the database:
  con = get_connection_interactively


  # Open the csv file and check the the species names.  They should
  # already be in the database, and there should only be one row for
  # any given scientificname so that we have an unambiguous value for
  # species_id to use in the traits table.

  csv = CSV.open(input_file)

  everything = csv.read

  species_names = everything.collect { |row| row[0] }

  column_heading = species_names.shift

  if column_heading != "species.scientificname"
    puts "First field should be scientific name of species not " +
      "#{species_names[0]}."
    exit
  end


  SPECIES_CHECK = <<-SELECTION
      SELECT * FROM species
          WHERE scientificname = ?
  SELECTION

  are_errors = false
  species_names.each do |species_name|

    species_name_query = con.prepare(SPECIES_CHECK)
    species_name_query.execute(species_name)
    if species_name_query.size > 2
      puts "There is more than one row in the species table\n" +
        "with scientificname = #{species_name}."
      are_errors = true
    elsif species_name_query.size == 0
      puts "There are no rows in the species table\n" +
        "with scientificname = #{species_name}."
      are_errors = true
    end      
    
  end

  if are_errors
    puts "Fix species information and re-run script."
    exit
  end

  csv.rewind

  # Check that the header row is what we expect
  EXPECTED_HEADER = 
    %w(species.scientificname variable_id site_id date dateloc n mean SE)
  header = csv.readline
  check_csv_header(header, EXPECTED_HEADER)

  

  INSERT_STRING = <<-INSERTION
    INSERT INTO traits(citation_id,
                       site_id,
                       specie_id,
                       /*treatment_id,
                       cultivar_id,*/
                       date,
                       dateloc,
                       statname,
                       stat,
                       mean,
                       n,
                       /*notes,*/
                       created_at,
                       updated_at,
                       variable_id,
                       user_id,
                       checked,
                       access_level) 
               VALUES (?, /* citation_id */
                       ?, /* site_id */
                       (SELECT id FROM species WHERE scientificname = ?),
                       /*?,
                       ?,*/
                       ?, /* date */
                       ?, /* dateloc */
                       "SE", /* statname */
                       ?, /* stat */
                       ?, /* mean */
                       ?, /* n */
                       /*?,*/
                       NOW(), /* created_at */
                       NOW(), /* updated_at */
                       ?, /* variable_id */
                       ?, /* user_id */
                       ?, /* checked */
                       ?) /* access_level */
  INSERTION

  insert_statement = con.prepare(INSERT_STRING)

  citation_id = 738
  user_id = 2 # dlebauer
  checked = 0
  access_level = 4 
    
  # Iterate through the rows of the csv file and insert the data into
  # the sites table
  csv.each do |row|
    
    # assign row data to local varibles
    (species_scientificname, variable_id, site_id,
     date, dateloc, n, mean, stat) = row

    insert_statement.execute(citation_id,
                             site_id,
                             species_scientificname,
                             date,
                             dateloc,
                             stat,
                             mean,
                             n,
                             variable_id,
                             user_id,
                             checked,
                             access_level) 

  end

rescue Mysql::Error => e
  puts "Error number: #{e.errno}"
  puts e.error
  if e.error =~ /more than 1 row/
    puts species_scientificname
  end
  puts e.backtrace.join("\n")
  puts "The script could not finish.  Please correct any errors, clean up " +
    "changes to\nthe traits table, and re-run the script."
  
ensure
  con.close if con
end
