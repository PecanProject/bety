require '../uploadsugarcane/utilities.rb'

# MAIN PROGRAM

species_scientificname, variable_id, site_id, date, dateloc, n, mean, stat = 0, 0, 0, 0, 0, 0, 0, 0

begin

  # First get open the csv file and check the header:


  csv = CSV.open(get_input_file("sugarcaneyields.csv"))

  # Check that the header row is what we expect
  EXPECTED_HEADER = %w(species.scientificname variable_id site_id date dateloc n mean SE)
  header = csv.readline

  check_csv_header(header, EXPECTED_HEADER)

  

  # Now open a connection to the database:

  con = get_connection_interactively

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
    
  # Iterate through the rows of the csv file and insert the data into the sites table
  csv.each do |row|
    
    # assign row data to local varibles
    (species_scientificname, variable_id, site_id, date, dateloc, n, mean, stat) = row

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
  puts e.errno
  puts e.error
  if e.error =~ /more than 1 row/
    puts species_scientificname
  end
  puts e.backtrace.join("\n")
  
ensure
  con.close if con
end
