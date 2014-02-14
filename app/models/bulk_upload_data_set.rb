class BulkUploadDataSet
  attr_reader :data, :headers, :validation_summary, :csv_warnings, :file_has_fatal_errors, :validated_data

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
      raise "csvpath is missing form the session"
    end

    begin
      # Get data out of the file and store in @headers and @data:
      read_data

      
    end



  end








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

  public
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
  def validate_csv_data
    @validated_data = []
    @data.each do |row|
      validated_row = row.collect { |value| { fieldname: value[0], data: value[1] } }
      @validated_data << validated_row
    end

    @validated_data.each_with_index do |row, i|
      row_number = i + 1
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

          if doi_of_existing_citation?(column[:data])
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

          if existing_site?(column[:data])
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

        when "treatment"

          if existing_treatment?(column[:data])
            column[:validation_result] = :valid
          else
            column[:validation_result] = :fatal_error
            column[:validation_message] = "Not found in treatments table"
            if @validation_summary.has_key? :unresolvable_treatment_reference
              @validation_summary[:unresolvable_treatment_reference] << row_number
            else
              @validation_summary[:unresolvable_treatment_reference] = [ row_number ]
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
              if existing_cultivar(column[:data], species_id)
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
        name_index = row.index { |h| h[:fieldname] == "citation_title" }
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
          if @validation_summary.has_key? :unresolvable_citation_reference
            @validation_summary[:unresolvable_citation_reference] << row_number
          else
            @validation_summary[:unresolvable_citation_reference] = [ row_number ]
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


  private


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

  def existing_treatment?(name)
    t = Treatment.find_by_name(name)
    return t
  end

  def doi_of_existing_citation?(doi)
    c = Citation.find_by_doi(doi)
    return c
  end

  def existing_citation(author, year, title)
    c = Citation.where("author = :author AND year = :year AND title LIKE :title_matcher",
                       { author: author, year: year, title_matcher: "#{title}%" })
    return c.size == 1
  end

  def existing_cultivar(name, species_id)
    c = Cultivar.where("name = :name AND specie_id = :species_id",
                       { name: name, species_id: species_id })
    return c.size == 1
  end


end
