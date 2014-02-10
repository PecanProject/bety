class BulkUploadController < ApplicationController

  # step 1: Choose a file to upload.
  def start_upload
  end

  # step 2: Display the CSV file as a table.
  #
  # Session variables set:
  #     "csvpath", the path to where the uploaded file is stored
  # Instance variables set:
  #     @data, a CSV object containing the CSV file data
  #     @headers, an array of the headers of the CSV file; equals the corresponding session variable
  #     @errors (if there are any)
  def display_csv_file
    error = nil

    # Store the selected CSV file if we got here via the "upload file" button:
    if params["new upload"]
      uploaded_io = params["CSV file"]
      if uploaded_io
        store_file(uploaded_io)
      else
        # blank submission; no file was chosen
        session[:csvpath] = nil
      end
      session[:mapping] = nil # any existing mapping was for a (possibly) different file
    end

    # Get data out of the file and store in @headers and @data:
    if session[:csvpath]
      begin
        validate_csv = true # check CSV file is well-formed and throw exception if not
        read_data(validate_csv) # read CSV file at session[:cvspath] and set @data and @headers
      rescue CSV::MalformedCSVError => e
        flash[:error] = e.message
        redirect_to(action: "start_upload")
      end
    else
      flash[:error] = "No file chosen"
      redirect_to(action: "start_upload")
    end

  end


  # step 3
  def map_data
    # reads CSV file and sets @data and @headers
    read_data # uses session[:csvpath] to set @headers and @data
    @displayed_columns = displayed_columns
  end


  # step 4
  def confirm_data

    # reads CSV file and sets @data and @headers
    read_data

    # Only set the mapping session value if the value from params is
    # non-nil: we might get here from a failed attempt at insert_data.
    if !params["mapping"].nil?
      session[:mapping] = params["mapping"]
    end
    @mapping = session[:mapping]

    # set @mapped_data from @data based on the mapping
    get_insertion_data(true)

    @displayed_columns = displayed_columns


    respond_to do |format|
      format.html {
        if @global_errors.size > 0
          flash[:error] = @global_errors
          redirect_to(action: "map_data")
        else
          render
        end
      }
    end

  end

  # step 5
  def insert_data
    # reads CSV file and sets @data and @headers
    read_data
    get_insertion_data

    if @errors
      flash[:error] = @errors
      redirect_to(action: "confirm_data")
      return
    end

    errors = nil
    begin
      Trait.transaction do
        @mapped_data.each do |row|
          Trait.create!(row)
        end
      end
    rescue => e
      errors = e.message
    end

    respond_to do |format|
      format.html {
        if errors
          flash[:error] = errors
          redirect_to(action: "confirm_data")
        else
          redirect_to(action: "start_upload")
        end
      }
    end
  end
    




  private

  
  def store_file(uploaded_io)
    file = File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb')
    file.write(uploaded_io.read)
    session[:csvpath] = file.path
    file.close
  end

  # Uses: 
  #     session[:csvpath], the path to the uploaded CSV file
  # Sets:
  #     @headers, the CSV file's header info
  #     @data, a CSV object corresponding to the uploaded file,
  #         positioned to read the first line after the header line
  def read_data(validate_csv = false)
    
    csvpath = session[:csvpath]
    
    csv = CSV.open(csvpath, { headers: true })

    if validate_csv
      # Checks that the file referenced by the CSV object @data is
      # well formed and triggers a CSV::MalformedCSVError exception if
      # it is not.
      csv.each do |row| # force exception if not well formed
        row.each do |c|
        end
      end

      csv.rewind # rewinds to the first line
    end

    csv.readline # need to read first line to get headers
    @headers = csv.headers
    csv.rewind

    # store CSV object in instance variable
    @data = csv

  end

  # Uses the specified data mapping to convert @data from a CSV object
  # to an Array of Hashes suitable for inserting into the traits
  # table.
  def get_insertion_data(for_display = false)
    mapping = session[:mapping]

    user_supplied_values = mapping["value"]

    validate(user_supplied_values)

    @database_default_values = {}
    Trait.columns.each do |col|
      @database_default_values[col.name] = col.default
    end

    # combine user-supplied values with database defaults
    defaults = @database_default_values.merge(user_supplied_values) # user-supplied values take precedence over database defaults
    if for_display
      # replace nil and empty string with "NULL"
      defaults.each do |k, v|
        if v.nil? or v.to_s.empty?
          defaults[k] = "NULL"
        end
      end
    end

    @errors = false
    @mapped_data = Array.new
    @data.each do |csv_row|
      csv_row_as_hash = csv_row.to_hash

      # look up scientificname to get specie_id (if needed)
      species_key = nil
      if @headers.include?("scientificname")
        species_key = "scientificname"
      elsif @headers.include?("species.scientificname")
        species_key = "species.scientificname"
      end
      if !species_key.nil?
        sp = nil
        begin
          sp = Specie.find_by_scientificname(csv_row_as_hash[species_key])
        rescue
        end
        if sp
          csv_row_as_hash["specie_id"] = sp.id.to_s
        else
          csv_row_as_hash["specie_id"] = for_display ? "#{csv_row_as_hash[species_key]} NOT FOUND" : nil
          @errors = "Can't submit invalid data.<br>Values highlighted in red were not found in the database"
        end
      end

      # apply rounding
      if csv_row_as_hash["mean"]
        precision = mapping["rounding"]["mean"].to_i
        csv_row_as_hash["mean"] = sprintf("%.#{precision}f", csv_row_as_hash["mean"].to_f.round(precision))
      end
      if csv_row_as_hash["stat"]
        precision = mapping["rounding"]["stat"].to_i
        csv_row_as_hash["stat"] = sprintf("%.#{precision}f", csv_row_as_hash["stat"].to_f.round(precision))
      end

      mapped_row = defaults.merge(csv_row_as_hash) # csv row values take precedence over defaults

      # eliminate extraneous data from CSV row
      mapped_row.keep_if { |key, value| Trait.columns.collect { |column| column.name }.include?(key) }

      @mapped_data << mapped_row

    end

    @mapped_data
  end

  def displayed_columns
    Trait.columns.select { |col| !['id', 'created_at', 'updated_at'].include?(col.name) }
  end

  def validate(user_supplied_data)
    @global_errors ||= []
    user_supplied_data.each do |column, value|
      if value.nil? or value.to_s.empty?
        next
      end
      if column.match(/_id$/)
        tablename = column.sub(/_id$/, '').classify
        if tablename == "Method"
          tablename = "Methods"
        end
        table = tablename.constantize
        logger.info("table is #{tablename}")
        if !table.find_by_id(value)
          @global_errors << "Couldn't find row with id #{value} in table #{tablename}"
        end
      end
    end
  end

end
