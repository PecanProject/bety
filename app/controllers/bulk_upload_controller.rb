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

    # Store the selected CSV file if we got here via the "upload file" button:
    if params["new upload"]
      uploaded_io = params["CSV file"]
      if uploaded_io
        store_file(uploaded_io)
      else
        # blank submission; no file was chosen
        flash[:error] = "No file chosen"
        redirect_to(action: "start_upload")
        return # we're done here
      end
    end

    # Get data out of the file and store in @headers and @data:
    begin
      validate_csv = true # check CSV file is well-formed and throw exception if not
      read_data(validate_csv) # read CSV file at session[:cvspath] and set @data and @headers
    rescue CSV::MalformedCSVError => e
      flash[:error] = "Couldn't parse #{File.basename(session[:csvpath])}: #{e.message}"
      # flash[:display_csv_file] = true
      redirect_to(action: "start_upload")
      return
    rescue ArgumentError => e
      flash[:error] = e.message
      redirect_to(action: "start_upload")
      return
    end

    check_header_list

    if @csv_errors.any?
      # to do: decide whether to go on to validate data even when there are errors in the heading field list
#      return
    end

    # No heading errors; go on to validate data
    validate_csv_data
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

  def read_raw_contents
    csvpath = session[:csvpath]
    csv = File.open(csvpath)
    @file_contents = csv.read
    csv.close
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

  RECOGNIZED_COLUMNS =  %w{yield citation_doi citation_author citation_year citation_title site species treatment access_level cultivar date n SE notes}
  def check_header_list

    @csv_errors = []
    @csv_warnings = []

    # Check for required yields field
    if !@headers.include?('yield')
      @csv_errors << "You must have a yield column in your CSV file."
    end

    # Check for consistent stat information
    if @headers.include?('SE') && !@headers.include?('n')
      @csv_errors << 'If you have an "SE" column, you must have an "n" column as well.'
    elsif !@headers.include?("SE") && @headers.include?("n")
      @csv_errors << 'If you have an "n" column, you must have an "SE" column as well.'
    end

    # Check citation information
    if @headers.include?('citation_doi') && (@headers.include?('citation_author') || @headers.include?('citation_year') || @headers.include?('citation_title'))
      @csv_errors << 'If you include a "citation_doi" column, then you must not include columns for "citation_author", "citation_title", or "citation_year."'
    elsif @headers.include?('citation_author') && (!@headers.include?('citation_year') || !@headers.include?('citation_title'))
      @csv_errors << 'If you include a "citation_author" column, then you must also include columns for "citation_title" and "citation_year."'
    elsif @headers.include?('citation_title') && (!@headers.include?('citation_author') || !@headers.include?('citation_year'))
      @csv_errors << 'If you include a "citation_title" column, then you must also include columns for "citation_author" and "citation_year."'
    elsif @headers.include?('citation_year') && (!@headers.include?('citation_author') || !@headers.include?('citation_title'))
      @csv_errors << 'If you include a "citation_year" column, then you must also include columns for "citation_title" and "citation_author."'
    end

    ignored_columns = []
    @headers.each do |field_name|
      if !RECOGNIZED_COLUMNS.include? field_name
        ignored_columns << field_name
      end
    end

    if ignored_columns.size > 0
      @csv_warnings << "These columns will be ignored:<br>#{ignored_columns.join('<br>')}"
    end
    
  end

  REQUIRED_DATE_FORMAT = /^(?<year>\d\d\d\d)(-(?<month>\d\d)(-(?<day>\d\d))?)?$/

  # Given a CSV object (vis. "@data") with lineno = 0, convert it to
  # an array of arrays of hashes where each hash has at least two
  # keys: :data for the data value copied from the CSV object, and
  # :validation_result, the result of performing validation on that
  # value.  For invalid data, a third key, :validation_message, gives
  # details about the validation error.
  def validate_csv_data
    @validated_data = []
    @data.each do |row|
      validated_row = row.collect { |value| { fieldname: value[0], data: value[1] } }
      @validated_data << validated_row
    end

    @validated_data.each do |row|
      row.each do |column|
        case column[:fieldname]

        when "yield"

          begin
            Float(column[:data])
            column[:validation_result] = :valid
          rescue ArgumentError => e
            column[:validation_result] = :fatal_error
            column[:validation_message] = e.message
          end

        when "citation_doi"

          if doi_of_existing_citation?(column[:data])
            column[:validation_result] = :valid
          else
            column[:validation_result] = :fatal_error
            column[:validation_message] = "Not found in citations table"
          end

        when "citation_author"

          # accept anything for now

        when "citation_year"

          begin
            year = Integer(column[:data])
            if year > Date.today.next_year.year
              # Don't allow citation year to be more than one year in the future
              column[:validation_result] = :fatal_error
              column[:validation_message] = "Citation year is in the future."
            elsif year < 1436
              column[:validation_result] = :fatal_error
              column[:validation_message] = "Citation year is before Gutenberg invented his press!"
            end
          rescue ArgumentError => e
            column[:validation_result] = :fatal_error
            column[:validation_message] = e.message
          end

        when "citation_title"

          # accept anything for now
        
        when "site"

          if existing_site?(column[:data])
            column[:validation_result] = :valid
          else
            column[:validation_result] = :fatal_error
            column[:validation_message] = "Not found in sites table"
          end

        when "species"

          if existing_species?(column[:data])
            column[:validation_result] = :valid
          else
            column[:validation_result] = :fatal_error
            column[:validation_message] = "Not found in species table"
          end

        when "treatment"

          if existing_treatment?(column[:data])
            column[:validation_result] = :valid
          else
            column[:validation_result] = :fatal_error
            column[:validation_message] = "Not found in treatments table"
          end

        when "access_level"

          access_level = Integer(column[:data])
          if !(1..4).include? access_level
            column[:validation_result] = :fatal_error
            column[:validation_message] = "access_level must be 1, 2, 3, or 4"
          else
            column[:validation_result] = :valid
          end

        when "cultivar"

          # skip for now

        when "date"

          year = month = day = nil
          REQUIRED_DATE_FORMAT.match column[:data] do |match_data|
            # to-do: set an appropriate dateloc value when day or month is not supplied
            year = match_data[:year]
            month = match_data[:month] || 1
            day = match_data[:day] || 1
          end

          if year.nil?
            column[:validation_result] = :fatal_error
            column[:validation_message] = "dates must be in the form 1999-01-01, 1999-01, or 1999"
          else
            # Make sure it's a valid date
            begin
              date = Date.new(year.to_i, month.to_i, day.to_i)

              # Date is valid; but make sure the range is reasonable
              
              if date > Date.today
                # Don't allow date to be in the future
                column[:validation_result] = :fatal_error
                column[:validation_message] = "Date is in the future."
              else
                column[:validation_result] = :valid
              end
            rescue ArgumentError => e
              column[:validation_result] = :fatal_error
              column[:validation_message] = e.message + "year: #{year}; month: #{month}; day: #{day}"
            end
          end

        when "n"

          begin
            n = Integer(column[:data])
            if n <= 1
              column[:validation_result] = :fatal_error
              column[:validation_message] = "n must be at least 2"
            else
              column[:validation_result] = :valid
            end
          rescue ArgumentError => e
            column[:validation_result] = :fatal_error
            column[:validation_message] = e.message
          end

        when "SE"

          begin
            Float(column[:data])
            # For now, accept any valid float
            column[:validation_result] = :valid
          rescue ArgumentError => e
            column[:validation_result] = :fatal_error
            column[:validation_message] = e.message
          end

        when "notes"

          # accept anything for now

        end # case

        # validation of citation information by author, year, and date
        # happens outside the case statement since it involves
        # multiple columns

        author_index = row.index { |h| h[:fieldname] == "citation_author" }
        year_index = row.index { |h| h[:fieldname] == "citation_year" }
        name_index = row.index { |h| h[:fieldname] == "citation_title" }
        logger.info(author_index)
        logger.info(year_index)
        logger.info(name_index)
        if existing_citation(row[author_index][:data], row[year_index][:data], row[name_index][:data])
          row[author_index][:validation_result] = :valid
          row[year_index][:validation_result] = :valid
          row[name_index][:validation_result] = :valid
        else
          row[author_index][:validation_result] = :fatal_error
          row[year_index][:validation_result] = :fatal_error
          row[name_index][:validation_result] = :fatal_error
          row[author_index][:validation_message] = "Couldn't find a unique matching citation for this row."
          row[year_index][:validation_message] = "Couldn't find a unique matching citation for this row."
          row[name_index][:validation_message] = "Couldn't find a unique matching citation for this row."
        end

      end # row.each

    end # @validated_data.each

  end # def validate_csv_data


  # TO-DO: Decide if these methods should fail if we don't find a
  # *unique* referent in the database (at least until we add
  # uniqueness constraints on the database).

  def existing_species?(name)
    s = Specie.find_by_scientificname(name)
    return !s.nil?
  end

  def existing_site?(name)
    s = Site.find_by_sitename(name)
    return !s.nil?
  end

  def existing_treatment?(name)
    t = Treatment.find_by_name(name)
    return !t.nil?
  end

  def doi_of_existing_citation?(doi)
    c = Citation.find_by_doi(doi)
    return !c.nil?
  end

  def existing_citation(author, year, title)
    c = Citation.where("author = :author AND year = :year AND title LIKE :title_matcher",
                       { author: author, year: year, title_matcher: "#{title}%" })
    return c.size == 1
  end

end
