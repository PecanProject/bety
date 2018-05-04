require 'pp'
require_relative 'postgres_helpers'

class EnhancedConnection < PG::Connection

  WrongMachineId = 99

  PublicTableQuery = <<PTQ
    SELECT table_name FROM information_schema.tables
        WHERE table_schema = 'public'
            AND is_insertable_into = 'YES'
PTQ

  PublicSequenceQuery = <<PSQ
    SELECT sequence_name FROM information_schema.sequences
        WHERE sequence_schema = 'public'
PSQ

  SequenceInfoQuery = <<SIQ
  SELECT sequence_name, last_value, is_called FROM %s
SIQ

  def initialize
    begin
      require 'yaml'
      connection_hash = YAML.load(File.new('database_specification.yml'))

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
    end

    super(connection_hash)
  end

  def set_correct_machine_id(id)
    @machine_id = id
  end
  
  
  def public_tables
    @public_tables || @public_tables = get_result_array_from_query(PublicTableQuery)
  end

  def public_sequences
    @public_sequences || @public_sequences = get_result_array_from_query(PublicSequenceQuery)
  end

  def table_sequence_pairs
    if @pairs
      return @pairs
    end
    
    @pairs = []

    public_tables.sort.each do |table|
      sequence = table_name_to_sequence_name(table)

      if public_sequences.include?(sequence)

        @pairs << [table, sequence]
      end
    end
    @pairs
  end

  # Returns an Array of 3-tuples, one for each sequence object having a
  # corresponding public table, consisting of the sequence object name, the
  # last_value column value, and the is_called column value.
  def sequence_info
    if @sequence_info
      return @sequence_info
    end
    
    @sequence_info = []
    table_sequence_pairs.each do |pair|
      result = exec(sprintf(SequenceInfoQuery, pair[1]))
      @sequence_info << result.values[0]
    end
    @sequence_info
  end

  # Returns an Array similar to that returned by sequence_info, but containing
  # only the 3-tuple where the value of last_value is in the range for the
  # machine with id = WrongMachineId.
  def filtered_sequence_info
    if @filtered_sequence_info
      @filtered_sequence_info
    end

    @filtered_sequence_info = sequence_info.select do |row|
      Integer(row[1]) / Integer(1e9) == WrongMachineId
    end

  end

  # Returns an Array of 2-tuple, one for each public table having a
  # corresponding sequence object that has an id in the range for the machine
  # with id = WrongMachineId.  Each tuple consists of the a table name and the
  # maximum id value from the bad range.
  def bad_id_info
    if @bad_id_info
      return @bad_id_info
    end

    bad_id_array = []
    table_sequence_pairs.map { |pair| pair[0] }.each do |table|
      result = exec(sprintf("SELECT max(id) FROM %s WHERE id / 1E9::int = #{WrongMachineId}", table))
      max_id = result.getvalue(0, 0)
      if max_id
        bad_id_array << [table, max_id]
      end
    end
    return @bad_id_info = bad_id_array
  end

  # Write an SQL statement for each table
  def generate_sql_fix_statements
    if @machine_id.nil?
      loop do
        @machine_id = prompt("Enter the correct machine id for this database: ")

        begin
          Integer(@machine_id)
          break
        rescue ArgumentError
          puts "Invalid integer; try again"
        end
      end
    end

    loop do
      if @output_file_name.nil?
        loop do
          @output_file_name = prompt("Enter output file name: ", "fix_ids.sql")
          if @output_file_name.strip != ''
            break
          end
          puts "Invalid name; try again"
        end
      end

      file_ok = true
      if File.exist?(@output_file_name)
        file_ok = false
        loop do
          answer = prompt("#{@output_file_name} exists; overwrite? (y or n)", 'n')
          case answer
          when 'y'
            file_ok = true
            break
          when 'n'
            break
          else
            puts "answer y or n"
          end
        end
      end
      
      if file_ok
        break
      else
        @output_file_name = nil
      end
    end


    f = File.new(@output_file_name, 'w')
    
    filtered_sequence_info.each do |row|
      sequence = row[0]
      table = sequence_name_to_table_name(sequence)

      # This sets the last_value column to the maximum existing id in the target
      # range, if such an id exists, and sets the is_called column value to
      # true.  If not such id exists, the last_value is set to the first value
      # of the targe range and the is_called column value is set to false.
      f.puts "SELECT setval('#{sequence}', " +
             "(SELECT COALESCE(MAX(id), (#{@machine_id}E9::bigint + 1)) FROM #{table} WHERE id / 1E9::int = #{@machine_id}), " +
             "(SELECT EXISTS(SELECT 1 FROM #{table} WHERE ID / 1E9::int = #{@machine_id})));"
    end
  end
  
  private

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

  def sequence_name_to_table_name(name)
    name[0..-8]
  end

  def table_name_to_sequence_name(name)
    name + '_id_seq'
  end

end
