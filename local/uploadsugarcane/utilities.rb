require 'csv'
require 'mysql' # This is the ruby-mysql gem, which allows prepared statements.

# Converts a date string of the form 14/2/09 or 14/2/2009 to a form
# that can be used in a MySQL insert statement
def convert_date(str)
  begin

  date_re = %r{^(\d\d?)/(\d\d?)/(\d\d(\d\d)?)$}
  match_data = date_re.match(str)
  if match_data.nil?
    puts "#{str} is not a recognized form of date"
    exit
  end
  (day, month, year) = match_data[1..3]
  if year.size == 2
    year = year.to_i
    if year < 69
      year += 2000
    else
      year += 1900
    end
    year = year.to_s
  end
  return "#{year}-#{month}-#{day}"

  rescue Exception => e
    puts e
    puts "str was #{str}"
    puts "year month and day were #{year}-#{month}-#{day}"

    exit
  end

end

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

def get_input_file(default)
  filename = prompt("input file name", default)
end


# Create a temporary table to store the a mapping from the CSV file's
# id string to the sites table insert id numbers
def create_temp_table(connection, tablename)

  mtempquery= "CREATE TABLE #{tablename}(name VARCHAR(25), id INT(11))"

  begin
    result = connection.query(mtempquery)
  rescue Mysql::ServerError::TableExistsError => e
    puts e.class
    puts "A table named '#{tablename}' already exists.  You must delete this table manually before running this script."
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
