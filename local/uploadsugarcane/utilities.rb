require 'csv'
require 'mysql' # This is the ruby-mysql gem, which allows prepared statements.

# Convenience method for prompting.
# Returns chomped response, or default if given and response is empty
def prompt(prompt_string = "?", default = "")
  print "#{prompt_string} (#{default}) "
  response = gets
  response.chomp!
  return response == "" ? default : response
end


# Prompts for host, username, password, and database name and returns
# a connection object (class Mysql)
def get_connection_interactively
  host = prompt("database host", "localhost")
  username = prompt("username", "root")
  password = prompt("password")
  database = prompt("database to use", "test")

  begin
    con = Mysql.new("#{host}","#{username}","#{password}","#{database}")
  rescue Mysql::Error => e
    puts e
    exit
  end
  con
end

def get_input_file
  filename = prompt("input file name", "sugarcanesites.csv")
end


# Create a temporary table to store the a mapping from the CSV files
# id string to the sites table insert id numbers
def create_temp_table(connection)

  mtempquery= "CREATE TABLE temp(name VARCHAR(25), id INT(11))"

  begin
    result = connection.query(mtempquery)
  rescue Mysql::Error => e
    puts e.class
    puts "A table named 'temp' already exists.  You must delete this table manually before running this script."
    exit
  end

end


def check_csv_header(header, expected_header)
  if (header == expected_header)
    puts "header is OK"
  else
    puts "CSV file header doesn't match expected header"
    puts "Found:"
    puts "\t#{header.join(", ")}"
    puts "Expected:"
    puts "\t#{expected_header.join(", ")}"
    exit
  end
end
