module PostgresHelpers

  ConnectionSpecFileName = 'connection_specification.yml'

  # Convenience method for prompting.
  # Returns chomped response, or default if given and response is empty
  def prompt(prompt_string = "?", default = "")
    print "#{prompt_string} (#{default}) "
    response = gets
    response.chomp!
    return response == "" ? default : response
  end

  def connection_hash
    connection_hash = Hash.new

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

    return connection_hash
  end

end
