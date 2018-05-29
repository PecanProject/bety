require 'pg'
require 'yaml'
require_relative 'postgres_helpers'

class EnhancedConnection < PG::Connection

  include PostgresHelpers

  PublicTableQuery = <<PTQ
    SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'public'
            AND is_insertable_into = 'YES'
PTQ

  # Initialize the connection, either from the YAML file
  # database_specification.yml if it exists or interactively from user input.
  def initialize
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
