class BulkUploadDataSet
  include ActionView::Helpers::NumberHelper # for rounding

  attr_reader :headers, :validated_data
  attr_reader :validation_summary, :csv_warnings
  attr_reader :file_has_fatal_errors, :total_error_count, :field_list_error_count, :data_value_error_count
  attr_reader :missing_interactively_specified_fields

  def initialize(session, uploaded_io = nil)

    @session = session

    if uploaded_io
      store_file(uploaded_io)
      @unvalidated = true
    else
      @unvalidated = false
    end

    if @session[:csvpath].nil?
      # shouldn't ever get here
      raise "csvpath is missing from the session"
    end

    # Get data out of the file and store in @headers and @data:
    read_data

  end

  # sets:
  #     @csv_warnings: a List of warning messages
  #     @validation_summary: a Hash containing the validation results;
  #         this method sets only the portion related to field list
  #         errors.
  def check_header_list

    @validation_summary = {}
    @validation_summary[:field_list_errors] = []
    @csv_warnings = []

    # Check for required yields field
    if !@headers.include?('yield')
      @validation_summary[:field_list_errors] << "You must have a yield column in your CSV file."
    end

    # Check for consistent stat information
    if @headers.include?('SE') && !@headers.include?('n')
      @validation_summary[:field_list_errors] << 'If you have an "SE" column, you must have an "n" column as well.'
    elsif !@headers.include?("SE") && @headers.include?("n")
      @validation_summary[:field_list_errors] << 'If you have an "n" column, you must have an "SE" column as well.'
    end

    # Check citation information
    if @headers.include?('citation_doi') && (@headers.include?('citation_author') || @headers.include?('citation_year') || @headers.include?('citation_title'))
      @validation_summary[:field_list_errors] << 'If you include a "citation_doi" column, then you must not include columns for "citation_author", "citation_title", or "citation_year."'
    elsif @headers.include?('citation_author') && (!@headers.include?('citation_year') || !@headers.include?('citation_title'))
      @validation_summary[:field_list_errors] << 'If you include a "citation_author" column, then you must also include columns for "citation_title" and "citation_year."'
    elsif @headers.include?('citation_title') && (!@headers.include?('citation_author') || !@headers.include?('citation_year'))
      @validation_summary[:field_list_errors] << 'If you include a "citation_title" column, then you must also include columns for "citation_author" and "citation_year."'
    elsif @headers.include?('citation_year') && (!@headers.include?('citation_author') || !@headers.include?('citation_title'))
      @validation_summary[:field_list_errors] << 'If you include a "citation_year" column, then you must also include columns for "citation_title" and "citation_author."'
    elsif @headers.include?('citation_author') || @headers.include?('citation_doi')
      # the upload file has citation information, so initialize a list of citation ids in the session variable
      @session[:citation_id_list] = []
    end

    # If cultivar is in the field list, species must be as well
    if @headers.include?('cultivar') && !@headers.include?('species')
      @validation_summary[:field_list_errors] << 'If you have a "cultivar" column, you must have a "species" column as well.'
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


  RECOGNIZED_COLUMNS =  %w{yield citation_doi citation_author citation_year citation_title site species treatment access_level cultivar date n SE notes}

  REQUIRED_DATE_FORMAT = /^(?<year>\d\d\d\d)(-(?<month>\d\d)(-(?<day>\d\d))?)?$/

  # Given a CSV object (vis. "@data") with lineno = 0, convert it to
  # an array of arrays of hashes where each hash has at least two
  # keys: :data for the data value copied from the CSV object, and
  # :validation_result, the result of performing validation on that
  # value.  For invalid data, a third key, :validation_message, gives
  # details about the validation error.
  #
  # This method sets or alters the following instance variables:
  #     @validation_summary:
  #         A key is added for each type of error found; the
  #         corresponding value is a list of rows (by number) where
  #         that type of error was found
  #     @validated_data:
  #         This is a list of Hashes, one hash for each row of the
  #         input file (excluding the heading row).  Each hash has
  #         these keys:
  #             fieldname: The field name for the corresponding value
  #                 (as given by the heading)
  #             data: The value itself, except with nil values
  #                 normalized to the empty string
  #         If validation on a particular value fails, these keys are
  #         added:
  #             validation_result: This will always be :valid,
  #                 :ignored, or :fatal_error
  #             validation_message: This gives information about the
  #                 nature of the validation error.
  #     @field_list_error_count:
  #         The number of errors pertaining to the field list of the uploaded file.
  #     @data_value_error_count:
  #         The number of data values that failed validation
  #     @total_error_count:
  #         The total number of errors, both heading-related and data-related.
  #     @file_has_fatal_errors:
  #         A boolean telling whether there were any fatal errors found.
  def validate_csv_data(session)
    @validated_data = []
    @data.each do |row|
      validated_row = row.collect { |value| { fieldname: value[0], data: value[1] } }
      @validated_data << validated_row
    end

    @validated_data.each_with_index do |row, i|
      row_number = i + 1

      # collect some data about the row as we do the validation
      citation_id = nil
      site_id = nil
      treatment_id = nil

      row.each do |column|

        column[:data] ||= ""

        case column[:fieldname]

        when "yield"

          begin
            # yield is a keyword; hence "amount_of_yield"
            amount_of_yield = Float(column[:data])
            if amount_of_yield <= 0
              column[:validation_result] = :fatal_error
              column[:validation_message] = "yield can't be less than zero"
              if @validation_summary.has_key? :negative_yield
                @validation_summary[:negative_yield] << row_number
              else
                @validation_summary[:negative_yield] = [ row_number ]
              end
            else
              column[:validation_result] = :valid
            end
          rescue ArgumentError => e
            column[:validation_result] = :fatal_error
            column[:validation_message] = e.message
            if @validation_summary.has_key? :unparsable_yield
              @validation_summary[:unparsable_yield] << row_number
            else
              @validation_summary[:unparsable_yield] = [ row_number ]
            end
          end

        when "citation_doi"

          if citation_id = doi_of_existing_citation?(column[:data])
            column[:validation_result] = :valid
          else
            column[:validation_result] = :fatal_error
            column[:validation_message] = "Not found in citations table"
            if @validation_summary.has_key? :unresolvable_citation_reference
              @validation_summary[:unresolvable_citation_reference] << row_number
            else
              @validation_summary[:unresolvable_citation_reference] = [ row_number ]
            end
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
              if @validation_summary.has_key? :future_citation_year
                @validation_summary[:future_citation_year] << row_number
              else
                @validation_summary[:future_citation_year] = [ row_number ]
              end
            elsif year < 1436
              column[:validation_result] = :fatal_error
              column[:validation_message] = "Citation year is before Gutenberg invented his press!"
              if @validation_summary.has_key? :too_old_citation_year
                @validation_summary[:too_old_citation_year] << row_number
              else
                @validation_summary[:too_old_citation_year] = [ row_number ]
              end
            end
          rescue ArgumentError => e
            column[:validation_result] = :fatal_error
            column[:validation_message] = e.message
            if @validation_summary.has_key? :unparsable_citation_year
              @validation_summary[:unparsable_citation_year] << row_number
            else
              @validation_summary[:unparsable_citation_year] = [ row_number ]
            end
          end

        when "citation_title"

          # accept anything for now
          
        when "site"

          if site_id = existing_site?(column[:data])
            column[:validation_result] = :valid
          else
            column[:validation_result] = :fatal_error
            column[:validation_message] = "Not found in sites table"
            if @validation_summary.has_key? :unresolvable_site_reference
              @validation_summary[:unresolvable_site_reference] << row_number
            else
              @validation_summary[:unresolvable_site_reference] = [ row_number ]
            end
          end

        when "species"

          if existing_species?(column[:data])
            column[:validation_result] = :valid
          else
            column[:validation_result] = :fatal_error
            column[:validation_message] = "Not found in species table"
            if @validation_summary.has_key? :unresolvable_species_reference
              @validation_summary[:unresolvable_species_reference] << row_number
            else
              @validation_summary[:unresolvable_species_reference] = [ row_number ]
            end
          end

        when "access_level"

          begin
            access_level = Integer(column[:data])
            if !(1..4).include? access_level
              column[:validation_result] = :fatal_error
              column[:validation_message] = "access_level must be 1, 2, 3, or 4"
              if @validation_summary.has_key? :out_of_bounds_access_level
                @validation_summary[:out_of_bounds_access_level] << row_number
              else
                @validation_summary[:out_of_bounds_access_level] = [ row_number ]
              end
            else
              column[:validation_result] = :valid
            end
          rescue ArgumentError => e
            column[:validation_result] = :fatal_error
            column[:validation_message] = e.message
            if @validation_summary.has_key? :unparsable_access_level
              @validation_summary[:unparsable_access_level] << row_number
            else
              @validation_summary[:unparsable_access_level] = [ row_number ]
            end
          end

        when "cultivar"

          # we need the species id to validation this
          species_index = row.index { |h| h[:fieldname] == "species" }
          if species_index.nil?
            column[:validation_result] = :fatal_error
            column[:validation_message] = "Cultivar can't be looked up when species is not in the field list."
          else            
            species_id = existing_species?(row[species_index][:data])
            if species_id.nil?
              column[:validation_result] = :fatal_error
              column[:validation_message] = "Cultivar can't be looked up when species is not in species table."
            else
              if existing_cultivar?(column[:data], species_id)
                column[:validation_result] = :valid
              else
                column[:validation_result] = :fatal_error
                column[:validation_message] = "No cultivar for this species with this name found in cultivars table"
                if @validation_summary.has_key? :unresolvable_cultivar_reference
                  @validation_summary[:unresolvable_cultivar_reference] << row_number
                else
                  @validation_summary[:unresolvable_cultivar_reference] = [ row_number ]
                end
              end
            end
          end

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
            if @validation_summary.has_key? :unacceptable_date_format
              @validation_summary[:unacceptable_date_format] << row_number
            else
              @validation_summary[:unacceptable_date_format] = [ row_number ]
            end
          else
            # Make sure it's a valid date
            begin
              date = Date.new(year.to_i, month.to_i, day.to_i)

              # Date is valid; but make sure the range is reasonable
              
              if date > Date.today
                # Don't allow date to be in the future
                column[:validation_result] = :fatal_error
                column[:validation_message] = "Date is in the future."
                if @validation_summary.has_key? :future_date
                  @validation_summary[:future_date] << row_number
                else
                  @validation_summary[:future_date] = [ row_number ]
                end
              else
                column[:validation_result] = :valid
              end
            rescue ArgumentError => e
              column[:validation_result] = :fatal_error
              column[:validation_message] = e.message + "year: #{year}; month: #{month}; day: #{day}"
              if @validation_summary.has_key? :invalid_date
                @validation_summary[:invalid_date] << row_number
              else
                @validation_summary[:invalid_date] = [ row_number ]
              end
            end
          end

        when "n"

          begin
            n = Integer(column[:data])
            if n <= 1
              column[:validation_result] = :fatal_error
              column[:validation_message] = "n must be at least 2"
              if @validation_summary.has_key? :invalid_sample_size
                @validation_summary[:invalid_sample_size] << row_number
              else
                @validation_summary[:invalid_sample_size] = [ row_number ]
              end
            else
              column[:validation_result] = :valid
            end
          rescue ArgumentError => e
            column[:validation_result] = :fatal_error
            column[:validation_message] = e.message
            if @validation_summary.has_key? :unparsable_sample_size
              @validation_summary[:unparsable_sample_size] << row_number
            else
              @validation_summary[:unparsable_sample_size] = [ row_number ]
            end
          end

        when "SE"

          begin
            Float(column[:data])
            # For now, accept any valid float
            column[:validation_result] = :valid
          rescue ArgumentError => e
            column[:validation_result] = :fatal_error
            column[:validation_message] = e.message
            if @validation_summary.has_key? :unparsable_standard_error_value
              @validation_summary[:unparsable_standard_error_value] << row_number
            else
              @validation_summary[:unparsable_standard_error_value] = [ row_number ]
            end
          end

        when "notes"

          # accept anything for now

        else

          column[:validation_result] = :ignored
          column[:validation_message] = "This column will be ignored."

        end # case

      end # row.each

      # validation of citation information by author, year, and date
      # happens outside the case statement since it involves
      # multiple columns
      
      if @headers.include?('citation_author') && @headers.include?('citation_year') && @headers.include?('citation_title')

        author_index = row.index { |h| h[:fieldname] == "citation_author" }
        year_index = row.index { |h| h[:fieldname] == "citation_year" }
        title_index = row.index { |h| h[:fieldname] == "citation_title" }
        if citation_id = existing_citation(row[author_index][:data], row[year_index][:data], row[title_index][:data])
          row[author_index][:validation_result] = :valid
          row[year_index][:validation_result] = :valid
          row[title_index][:validation_result] = :valid
        else
          row[author_index][:validation_result] = :fatal_error
          row[year_index][:validation_result] = :fatal_error
          row[title_index][:validation_result] = :fatal_error
          row[author_index][:validation_message] = "Couldn't find a unique matching citation for this row."
          row[year_index][:validation_message] = "Couldn't find a unique matching citation for this row."
          row[title_index][:validation_message] = "Couldn't find a unique matching citation for this row."
          if @validation_summary.has_key? :unresolvable_citation_reference
            @validation_summary[:unresolvable_citation_reference] << row_number
          else
            @validation_summary[:unresolvable_citation_reference] = [ row_number ]
          end
        end

      end

      if citation_id
        if !@session[:citation_id_list].include?(citation_id)
          @session[:citation_id_list] << citation_id
        end
      else
        # There's no citation column; validate against the session citation.
        citation_id = @session[:citation]
      end

      if citation_id.nil?
        # to-do: decide how to handle this
      else
        citation = Citation.find_by_id(citation_id)

        # If a valid site was specified in this row, ensure that it is
        # consistent with the citation.
        if !site_id.nil?
          if !citation.sites.include?(site_id)
            site_index = row.index { |h| h[:fieldname] == "site" }

            row[site_index][:validation_result] = :fatal_error
            row[site_index][:validation_message] = "Site is not consistent with citation"
            if @validation_summary.has_key? :inconsistent_site_reference
              @validation_summary[:inconsistent_site_reference] << row_number
            else
              @validation_summary[:inconsistent_site_reference] = [ row_number ]
            end
          end
        end

        # If a treatment was specified in this row, ensure that it is
        # consistent with the citation.
        treatment_index = row.index { |h| h[:fieldname] == "treatment" }
        if !treatment_index.nil?
          treatment = row[treatment_index][:data]
          if citation.treatments.map {|t| t.name }.include?(treatment)
            row[treatment_index][:validation_result] = :valid
          else
            row[treatment_index][:validation_result] = :fatal_error
            row[treatment_index][:validation_message] = "Treatment is not consistent with citation"
            if @validation_summary.has_key? :inconsistent_treatment_reference
              @validation_summary[:inconsistent_treatment_reference] << row_number
            else
              @validation_summary[:inconsistent_treatment_reference] = [ row_number ]
            end
          end
        end  

      end
    end # @validated_data.each

    @field_list_error_count = @validation_summary[:field_list_errors].size
    @data_value_error_count = (@validation_summary.keys - [ :field_list_errors ]).
      collect{|key| @validation_summary[key].size}.reduce(:+) || 0 # || 0 "fixes" the case where there are no data value errors
    @total_error_count = @field_list_error_count + @data_value_error_count
    @file_has_fatal_errors = !@total_error_count.zero?

  end # def validate_csv_data

  INTERACTIVE_COLUMNS = %w{site species treatment access_level cultivar date}

  def need_interactively_specified_data
    !missing_interactively_specified_fields.empty?
  end

  def missing_interactively_specified_fields
    missing_columns = INTERACTIVE_COLUMNS - @headers
  end

  def need_citation_selection
    !@headers.include?("citation_author") && # only need to check one of citation_author, citation_year, and citation_title
      !@headers.include?("citation_doi") &&
      @session['citation'].nil?
  end

  def get_upload_sites
    site_names = []
    if @headers.include?("site")
      @data.each do |row|
        site_names << row["site"]
      end
    else
    end
    distinct_site_names = site_names.uniq
    upload_sites = []
    distinct_site_names.each do |site_name|
      upload_sites << Site.find_by_sitename(site_name)
    end
    upload_sites
  end

  # Uses the global data values specified interactively by the user to
  # convert @data to an Array of Hashes suitable for inserting into
  # the traits table.
  def get_insertion_data
    # Get interactively-specified values, or set to empty hash if nil:
    interactively_specified_values = @session["global_values"] || {}

    # Double-check that all form fields are were non-empty:
    interactively_specified_values.keep_if do |key, value|
      !(value.empty? || value.nil?)
    end

    # For each foreign-key column, look up the value to use and add
    # it to the hash:
    validation_errors = []
    
    # error_list is an "out" parameter
    global_values = lookup_and_add_ids({ input_hash: interactively_specified_values, error_list: validation_errors })

    if validation_errors.size > 0
      raise validation_errors.join("<br>").html_safe
    end

    # For bulk uploads, "checked" should always be set to zero:
    global_values.merge!({
        "checked" => 0,
        "user_id" => @session[:user_id]
    })

    if !@headers.include?("citation_author") && !@headers.include?("citation_doi")
      # if we get here, the citation id must be in the session
      global_values["citation_id"] = @session["citation"]
    end
                  
    @mapped_data = Array.new
    @data.each do |csv_row|
      csv_row_as_hash = csv_row.to_hash

      # Don't allow id values to be specified in CSV file:
      csv_row_as_hash.keep_if do |key, value|
        !(key =~ /_id/)
      end

      # error_list is anonymous here since we don't need to use it: we've already validated the per-row data
      id_values = lookup_and_add_ids({ input_hash: csv_row_as_hash, error_list: [] })

      csv_row_as_hash.merge!(id_values)

      # Merge the global interactively-specified values into this row:
      csv_row_as_hash.merge!(global_values)

      Rails.logger.debug("csv_row_as_hash = #{csv_row_as_hash.inspect}")
      # apply rounding to the yield
      rounded_yield = number_with_precision(csv_row_as_hash["yield"].to_f, precision: @session["rounding"]["yields"].to_i, significant: true)

      # In the yields table, the yield is stored in the "mean" column:
      csv_row_as_hash["mean"] = rounded_yield

      if csv_row_as_hash.has_key?("SE")
        # apply rounding to the standard error
        rounded_se = number_with_precision(csv_row_as_hash["SE"].to_f, precision: @session["rounding"]["SE"].to_i, significant: true)

        # In the yields table, the standard error is stored in the "stat" column:
        csv_row_as_hash["stat"] = rounded_se
        # The statname should be set to "SE":
        csv_row_as_hash["statname"] = "SE"
      end

=begin
      if csv_row_as_hash["mean"]
        precision = mapping["rounding"]["mean"].to_i
        csv_row_as_hash["mean"] = sprintf("%.#{precision}f", csv_row_as_hash["mean"].to_f.round(precision))
      end
      if csv_row_as_hash["stat"]
        precision = mapping["rounding"]["stat"].to_i
        csv_row_as_hash["stat"] = sprintf("%.#{precision}f", csv_row_as_hash["stat"].to_f.round(precision))
      end
=end

      # eliminate extraneous data from CSV row
      yield_columns = Yield.columns.collect { |column| column.name }
      csv_row_as_hash.keep_if do |key, value|
        yield_columns.include?(key)
      end

      @mapped_data << csv_row_as_hash

    end

    @mapped_data
  end

####################################################################################################################################
  private


  # Takes the file parameter submitted by the upload form, uploads the
  # file, and store a reference to it in the session.
  def store_file(uploaded_io)
    file = File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb')
    file.write(uploaded_io.read)
    @session[:csvpath] = file.path
    file.close
  end


  # Uses: 
  #     @session[:csvpath], the path to the uploaded CSV file
  # Sets:
  #     @headers, the CSV file's header info
  #     @data, a CSV object corresponding to the uploaded file,
  #         positioned to read the first line after the header line
  def read_data
    
    csvpath = @session[:csvpath]
    
    csv = CSV.open(csvpath, { headers: true })

    if @unvalidated
      # Checks that the file referenced by the CSV object @data is
      # well formed and triggers a CSV::MalformedCSVError exception if
      # it is not.
      csv.each do |row| # force exception if not well formed
        if row.size == 0
          raise "Blank lines are not allowed."
        end
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


  # TO-DO: Decide if these methods should fail if we don't find a
  # *unique* referent in the database (at least until we add
  # uniqueness constraints on the database).

  def existing_species?(name)
    s = Specie.find_by_scientificname(name)
    return s
  end

  def existing_site?(name)
    s = Site.find_by_sitename(name)
    return s
  end

  def existing_treatment?(name, citation_id)
    t = Citation.find(citation_id).treatments.find_by_name(name)
    return t
  end

  def doi_of_existing_citation?(doi)
    c = Citation.find_by_doi(doi)
    return c
  end

  def existing_citation(author, year, title)
    c = Citation.where("author = :author AND year = :year AND title LIKE :title_matcher",
                       { author: author, year: year, title_matcher: "#{title}%" })
    return c.first
  end

  def existing_cultivar?(name, species_id)
    c = Cultivar.where("name = :name AND specie_id = :species_id",
                       { name: name, species_id: species_id })
    return c.first
  end


  # This is called in two contexts: Once for the interactively
  # specified data, and once for each data row of the CSV file.
  def lookup_and_add_ids(args)
    specified_values = args[:input_hash]
    validation_errors = args[:error_list]
    
    id_values = {}

    # Put cultivar after species because we need the specie_id to look
    # up the cultivar, and put treatment after citation_doi and
    # citation_author because we need to look up the treatment_id by
    # the treatment name AND the citation.
    id_lookups = ["citation_doi", "citation_author", "site", "species", "treatment", "cultivar"]

    id_lookups.each do |key|
      if !specified_values.keys.include?(key)
        next
      end
      value = specified_values[key]
      
      case key
      when "site"
        site = existing_site?(value)
        if site.nil?
          validation_errors << "No site named \"#{value}\" in database."
        else
          id_values["site_id"] = site.id
        end
      when "species"
        species = existing_species?(value)
        if species.nil?
          validation_errors << "No species named \"#{value}\" in database."
        else
          id_values["specie_id"] = species.id
        end
      when "treatment"
        treatment = existing_treatment?(value, id_values["citation_id"] || @session[:citation_id_list][0])
        if treatment.nil?
          validation_errors << "No treatment named \"#{value}\" in database."
        else
          id_values["treatment_id"] = treatment.id
        end
      when "cultivar"
        # cultivar is optional ...
        if value.nil? or value.empty?
          next
        end
        # ... but if provided, it should validate
        cultivar = existing_cultivar?(value, id_values["specie_id"])
        if cultivar.nil?
          validation_errors << "No cultivar named \"#{value}\" in database."
        else
          id_values["cultivar_id"] = cultivar.id
        end
      when "citation_author"
        # This is never specified globally, so we only get here when it's a field in the CSV file
        citation = existing_citation(value, specified_values["citation_year"], specified_values["citation_title"])
        # no need to validate
        id_values["citation_id"] = citation.id
      when "citation_doi"
        # This is never specified globally, so we only get here when it's a field in the CSV file
        citation = doi_of_existing_citation?(value)
        # no need to validate
        id_values["citation_id"] = citation.id
      end # case
    end # each key

    specified_values.merge!(id_values)

  end

end
