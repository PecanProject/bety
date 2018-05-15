require 'pg'

# Convenience method for prompting.
# Returns chomped response, or default if given and response is empty
def prompt(prompt_string = "?", default = "")
  print "#{prompt_string} (#{default}) "
  response = gets
  response.chomp!
  return response == "" ? default : response
end


# Try to get connection information from a YAML file; otherwise, prompt for
# host, username, password, and database name.  Return a connection object.
def get_connection
  begin
    require 'yaml'
    connection_hash = YAML.load(File.new('database_specification.yml'))

    con = PG.connect(connection_hash)
  rescue => e
    puts e
    puts connection_hash

    host = prompt("database host", "localhost")
    username = prompt("username", "bety")
    password = prompt("password", "bety")
    database = prompt("database to use", "bety")

    connection_hash = { host: "#{host}",
                        user: "#{username}",
                        password: "#{password}",
                        dbname: "#{database}" }
    puts connection_hash

    con = PG.connect(connection_hash)
  end
  con
end
