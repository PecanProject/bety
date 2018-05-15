require 'yaml'
require_relative 'postgres_helpers'

class EnhancedConnection < PG::Connection

  ConnectionSpecFileName = 'connection_specification.yml'

  PublicTableQuery = <<PTQ
    SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'public'
            AND is_insertable_into = 'YES'
PTQ

  # Initialize the connection, either from the YAML file
  # database_specification.yml if it exists or interactively from user input.
  def initialize
    connection_hash = {}

    if File.exist?(ConnectionSpecFileName)
      f = File.new(ConnectionSpecFileName)
      begin
        initialization_hash = YAML.load(f)
        connection_hash = initialization_hash["connection_info"]
        @machine_id = initialization_hash["correct_machine_id"]
        @output_file_name = initialization_hash["output_file"]
      rescue Psych::SyntaxError => e
        puts e
        puts "There is a syntax error in your connection specification file."
        if prompt("Get connection info interactively?", "y") != "y"
          exit
        end
      end
    end

    if !connection_hash.has_key? 'host'
      connection_hash[:host] = prompt("database host", "localhost")
    end
    if !connection_hash.has_key? 'user'
      connection_hash[:user] = prompt("username", "bety")
    end
    if !connection_hash.has_key? 'password'
      connection_hash[:password] = prompt("password", "bety")
    end
    if !connection_hash.has_key? 'dbname'
      connection_hash[:dbname] = prompt("database to use", "bety")
    end
    if !connection_hash.has_key? 'port'
      connection_hash[:port] = prompt("port", "5432")
    end

    begin
      super(connection_hash)
    rescue => e
      puts "Couldn't connect using this connection specification:\n#{connection_hash.to_yaml}\n"
      exit
    end
  end

  # Return a list of "regular" public tables (that is, public tables that can be
  # inserted into).
  def public_tables
    @public_tables || @public_tables = get_result_array_from_query(PublicTableQuery)
  end

  private

  # Given a query with one item in its SELECT clause, return an array consisting
  # of the column of values in the result.
  def get_result_array_from_query(query)

    block # wait for connection to be ready before sending query
    send_query(query)
    set_single_row_mode
    result = get_result

    column_values = []
    result.stream_each_row do |row|
      column_values += row
    end
    column_values
  end

end
