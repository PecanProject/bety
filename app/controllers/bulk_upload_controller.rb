class BulkUploadController < ApplicationController

  # step 1: Choose a file to upload.
  def start_upload
    # To-do: decide whether to display raw content of CSV file when we can't parse it.
#    if flash[:display_csv_file]
#      read_raw_contents
#    end
    # clean session upload data
    session[:csvpath] = nil
    session[:mapping] = nil
  end

  # step 2: Display the CSV file as a table.
  def display_csv_file

    begin
      # Store the selected CSV file if we got here via the "upload file" button:
      if params["new upload"]
        uploaded_io = params["CSV file"]
        if uploaded_io
          @data_set = BulkUploadDataSet.new(session, uploaded_io)
        else
          # blank submission; no file was chosen
          flash[:error] = "No file chosen"
          redirect_to(action: "start_upload")
          return # we're done here
        end
      else
        @data_set = BulkUploadDataSet.new(session)
      end
    rescue CSV::MalformedCSVError => e
      flash[:error] = "Couldn't parse #{File.basename(session[:csvpath])}: #{e.message}"
      # flash[:display_csv_file] = true
      redirect_to(action: "start_upload")
      return
    rescue Exception => e # catches invalid UTF-8 byte sequence errors and empty lines
      flash[:error] = e.message
      redirect_to(action: "start_upload")
      return
    end

    @data_set.check_header_list # initializes @validation_summary and @validation_summary[:field_list_errors]

    if @data_set.validation_summary[:field_list_errors].any?
      # to do: decide whether to go on to validate data even when there are errors in the heading field list
#      return
    end

    # No heading errors; go on to validate data
    @data_set.validate_csv_data
  end


  # step 3
  def choose_global_data_values
    @data_set = BulkUploadDataSet.new(session)
  end
    

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
    



################################################################################
  private

  
  def store_file(uploaded_io)
    file = File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb')
    file.write(uploaded_io.read)
    session[:csvpath] = file.path
    file.close
  end

  def read_raw_contents
    csvpath = session[:csvpath]
    csv = File.open(csvpath)
    @file_contents = csv.read
    csv.close
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
