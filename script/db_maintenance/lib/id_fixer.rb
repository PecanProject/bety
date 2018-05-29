require_relative 'enhanced_connection'

class IdFixer < EnhancedConnection

  WrongMachineId = 99

  PublicSequenceQuery = <<PSQ
    SELECT sequence_name FROM information_schema.sequences
        WHERE sequence_schema = 'public'
PSQ

  SequenceInfoQuery = <<SIQ
  SELECT sequence_name, last_value, is_called FROM %s
SIQ

  # Set the id for the machine hosting the database being connected to.
  def set_correct_machine_id(id)
    @machine_id = id
  end

  # Return a list of public sequence objects, that is, sequence objects for
  # public tables.  (In some cases, the corresponding table may no longer
  # exist.)
  def public_sequences
    @public_sequences || @public_sequences = get_result_array_from_query(PublicSequenceQuery)
  end

  # Returns a list of table--sequence-object pairs, one for each public table
  # having a corresponding sequence object.
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

  # For each table whose corresponding sequence object has the wrong value for
  # last_value, write an SQL statement to update the sequence object so the it
  # generates id numbers in the correct range.  Then, for each table having any
  # id values in the wrong range, update the offending rows so that the id is in
  # the correct range.  It is the user's responsibility to ensure that each
  # referring table has a bona fide foreign-key constraint and that constraint
  # is set to "cascade on update".
  def generate_sql_fix_statements
    if @machine_id.nil? || @machine_id == 99
      loop do
        begin
          @machine_id = Integer(prompt("Enter the correct machine id for this database: "))
          if @machine_id == WrongMachineId
            puts "#{WrongMachineId} is not a valid choice of machine id.  Please choose another."
          else
            break
          end
        rescue ArgumentError
          puts "Invalid integer; try again"
        end
      end
    end

    loop do
      if @output_file_name.nil?
        loop do
          @output_file_name = prompt("Enter output file name: ", "fix_ids.psql")
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

    bad_id_info.each do |row|
      table = row[0]
      if ['inputs', 'models', 'posteriors'].include?(table)
        drop_dbfiles_constraint(f, table.capitalize[0..-2])
      end
      f.puts "UPDATE #{table} SET id = nextval('#{table_name_to_sequence_name(table)}') WHERE id / 1E9::int = #{WrongMachineId};"
      if ['inputs', 'models', 'posteriors'].include?(table)
        readd_dbfiles_constraint(f, table.capitalize[0..-2])
      end
    end

  end

  private

  def drop_dbfiles_constraint(f, container_type)
    f.puts "ALTER TABLE dbfiles DROP CONSTRAINT IF EXISTS valid_#{container_type.downcase}_refs;"
  end

  def readd_dbfiles_constraint(f, container_type)
    f.puts "ALTER TABLE dbfiles ADD CONSTRAINT valid_#{container_type.downcase}_refs CHECK (container_type != '#{container_type}' OR container_id = ANY(get_#{container_type.downcase}_ids()));"
  end

  def sequence_name_to_table_name(name)
    name[0..-8]
  end

  def table_name_to_sequence_name(name)
    name + '_id_seq'
  end

end
