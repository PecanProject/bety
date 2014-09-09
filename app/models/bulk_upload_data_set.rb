class BulkUploadDataSet
  include ActionView::Helpers::NumberHelper # for rounding

  # An Array consisting of the headers of the uploaded CSV file.  This is set upon instantiation.
  attr :headers

  # A list containing one item for each row of the input file (excluding the
  # heading row).  Each item is itself a list of hashes, one hash for each
  # column of the row.Each hash has these keys:
  # fieldname::
  #
  #   The field name for the corresponding value (as given by the heading)
  #
  # data::
  #   The value itself, except with nil values normalized to the empty string
  #
  # If validation on a particular value fails, these keys are added:
  #
  # validation_result::
  #
  #   This will always be :valid, :ignored, or :fatal_error.
  #
  # validation_message::
  #
  #   This gives information about the nature of the validation error.
  #
  #   This attribute is set by +validate_csv_data+ and used by the
  #   +display_csv_data+ template.
  #
  # ==== Example
  #   [
  #      [
  #        {:fieldname=>"date",
  #         :data=>"bogus date",
  #         :validation_result=>:fatal_error,
  #         :validation_message=>"dates must be in the form 1999-01-01, 1999-01, or 1999"},
  #        {:fieldname=>"mean",
  #         :data=>" 0.1",
  #         :validation_result=>:ignored,
  #         :validation_message=>"This column will be ignored."}
  #      ],
  #      [
  #        {:fieldname=>"date",
  #         :data=>"666        ",
  #         :validation_result=>:fatal_error,
  #         :validation_message=>"dates must be in the form 1999-01-01, 1999-01, or 1999"},
  #       {:fieldname=>"mean",
  #        :data=>" 0.1",
  #        :validation_result=>:ignored,
  #        :validation_message=>"This column will be ignored."}
  #     ],
  #     [
  #       {:fieldname=>"date",
  #        :data=>"1066-13-5",
  #        :validation_result=>:fatal_error,
  #        :validation_message=>"dates must be in the form 1999-01-01, 1999-01, or 1999"},
  #       {:fieldname=>"mean",
  #        :data=>"   0.1",
  #        :validation_result=>:ignored,
  #        :validation_message=>"This column will be ignored."}
  #     ]
  #   ]
  #
  attr :validated_data

  # Once initialized by +check_header_list+, this is Hash object containing a
  # summary of validation results.  One key, +:field_list_errors+, contains
  # information about all the errors having to do with the header list.  This
  # key is added and its value is set in +check_header_list+.  In addition, the
  # data validation process of method +validate_csv_data+ adds a key for each
  # type of error found, and the value of each such key consists of a list of
  # row numbers where the corresponding error was found.
  # ==== Example
  #   {:field_list_errors=>["You must have a yield column in your CSV file."],
  #    :unacceptable_date_format=>[1, 2, 3]}
  attr :validation_summary

  # A list of warnings.  Set by +check_header_list+ and used by the
  # +display_csv_file+ template.  This list is either empty or is a string
  # listing all columns specified in the upload file's header line that are not
  # recognized as significant.
  attr :csv_warnings

  # Set by +validate_csv_data+ and used by the +display_csv_file+ template, both
  # directly (to determine if forward wizard links should be shown) and via the
  # +make_validation_summary+ helper (to determine if an error summary should be
  # displayed).
  attr :file_has_fatal_errors

  # Set by +validate_csv_data+ and used by the +display_csv_file+ template (via
  # the +make_validation_summary+ helper) to display the number of errors found.
  attr :total_error_count

  # Set by +validate_csv_data+ and used by the +make_validation_summary+ helper
  # to determine if a section detailing field list errors should be displayed.
  attr :field_list_error_count

  # Set by +validate_csv_data+ and used by the +make_validation_summary+ helper
  # to determine if a section detailing data value errors should be displayed.
  attr :data_value_error_count



  # Instantiates an object representing the data in the file +uploaded_io+ (if
  # provided) or in the file at <tt>session[:csvpath]</tt> (if uploaded_io was
  # not given).
  #
  # If provided, the temporary file +uploaded_io+ is read and the contents are
  # then written out to a file at
  # <tt>public/uploads/<uploaded_io.original_filename></tt>.  The location of
  # this file is then stored in the session under the key +:csvpath+.
  #
  # Prior to instantiation, the file is checked to ensure it is parseable as CSV
  # and contains no blank lines.  If a blank line is found, a +RunError+ is
  # raised and if the file is not parsable as CSV, a
  # <tt>CSV::MalformedCSVError</tt> is raised.  Otherwise, the +headers+
  # attribute is set and the file's data is stored internally.
  #
  # [session] The Hash object representing the current session, an instance of
  #           ActionDispatch::Session::AbstractStore::SessionHash.
  # [uploaded_io] An object representing the uploaded file, an instance of
  #               <tt>ActionDispatch::Http::UploadedFile</tt> (default: nil).
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

    # Mark whether this is yield data:
    if @headers.include?('yield')
      # mark this as a yield upload
      @is_yield_data = true
    else
      @is_yield_data = false
    end

  end

  def yield_data?
    @is_yield_data
  end

  def trait_data?
    !@is_yield_data
  end

  # Checks the heading of the uploaded file and sets the attributes
  # +csv_warnings+ and +validation_summary+.  (This method sets only the portion
  # of +validation_summary+ related to field list errors.)  Used by the
  # +display_csv_file+ action.
  def check_header_list

    @validation_summary = {}
    @validation_summary[:field_list_errors] = []
    @csv_warnings = []

    # This sets @traits_in_heading, @required_covariates, and @allowed_covariates.
    get_trait_and_covariate_info

    if yield_data?
      if !@traits_in_heading.empty?
        @validation_summary[:field_list_errors] << 'If you have a "yield" column, you can not also have column names matching recognized trait variable names.'
      end
    else
      if @traits_in_heading.empty?
        @validation_summary[:field_list_errors] << 'In your CSV file, you must either have a "yield" column or you must have a column that matches the name of acceptable trait variable.'
      else
        required_covariate_names = @required_covariates.collect { |c| c.name }
        covariate_names_not_in_heading = required_covariate_names - @headers
        if !covariate_names_not_in_heading.empty?
          @validation_summary[:field_list_errors] << "These required covariate variable names are not in your heading: #{covariate_names_not_in_heading.join(', ')}"
        end
      end
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
      if !(RECOGNIZED_COLUMNS + @traits_in_heading + @allowed_covariates).include? field_name
        ignored_columns << field_name
      end
    end

    if ignored_columns.size > 0
      @csv_warnings << "These columns will be ignored:<br>#{ignored_columns.join('<br>')}"
    end

  end

  # A list of recognized column heading strings.
  RECOGNIZED_COLUMNS =  %w{yield citation_doi citation_author citation_year citation_title site species treatment access_level cultivar date n SE notes}

  # A regular expression that must be matched by dates specified in the upload file.
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
  def validate_csv_data
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
            if amount_of_yield < 0
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
              if column[:data].strip.empty? || # cultivar is optional!
                  existing_cultivar?(column[:data], species_id)
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

        else # either a trait or covariate variable name or will be ignored

          if trait_data?
            get_trait_and_covariate_info
          end
          if trait_data? && (@traits_in_heading + @allowed_covariates).include?(column[:fieldname])
            column[:validation_result] = :valid # reset below if we find otherwise

            begin
              value = Float(column[:data])

              v = Variable.find_by_name(column[:fieldname])

              if !v.min.nil? and value < v.min.to_f
                column[:validation_result] = :fatal_error
                column[:validation_message] = "The value of the #{v.name} trait must be at least #{v.min}."
                if @validation_summary.has_key? :out_of_range_value
                  @validation_summary[:out_of_range_value] << row_number
                else
                  @validation_summary[:out_of_range_value] = [ row_number ]
                end
              end

              if !v.max.nil? and value > v.max.to_f
                column[:validation_result] = :fatal_error
                column[:validation_message] = "The value of the #{v.name} trait must be at most #{v.max}."
                if @validation_summary.has_key? :out_of_range_value
                  @validation_summary[:out_of_range_value] << row_number
                else
                  @validation_summary[:out_of_range_value] = [ row_number ]
                end
              end

            rescue ArgumentError => e
              column[:validation_result] = :fatal_error
              column[:validation_message] = e.message
              if @validation_summary.has_key? :unparsable_number
                @validation_summary[:unparsable_number] << row_number
              else
                @validation_summary[:unparsable_number] = [ row_number ]
              end
            end
          else
            column[:validation_result] = :ignored
            column[:validation_message] = "This column will be ignored."
          end

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

  # A list of values that may be specified interactively for the data set as a
  # whole.
  INTERACTIVE_COLUMNS = %w{site species treatment access_level cultivar date}

  # Returns true if there are column values missing from the upload file that
  # must therefor be specified interactively.  Used by the +display_csv_file+
  # and +confirm_data+ templates to determine whether the
  # +choose_global_data_values+ step should be included in the Wizard sequence.
  # the +choose_global_data_values+ template.
  def need_interactively_specified_data
    !missing_interactively_specified_fields.empty?
  end

  # Return a list of column values that need to be specified globally for the
  # dataset as a whole because they are missing from the upload file.
  def missing_interactively_specified_fields
    missing_columns = INTERACTIVE_COLUMNS - @headers
  end

  # Returns true if the upload file contains no citation information and no
  # citation has be selected for the session.  Used by the +display_csv_file+
  # template to determine whether to display a link to the citation selection
  # page.
  def need_citation_selection
    !@headers.include?("citation_author") && # only need to check one of citation_author, citation_year, and citation_title
      !@headers.include?("citation_doi") &&
      @session['citation'].nil?
  end

  # Returns the list of Sites used by the data set, or the Site specified
  # globally if site information was not included in the upload file.  Raises a
  # RuntimeError no match is found for some site in the data set.  Used by the
  # +confirm_data+ action.
  def get_upload_sites
    @data.rewind

    site_names = []
    if @headers.include?("site")
      @data.each do |row|
        site_names << row["site"]
      end
    else
      global_site = @session[:global_values][:site]
      if global_site.empty?
        raise "Site name can't be blank"
      end
      site_names << global_site
    end
    distinct_site_names = site_names.uniq
    upload_sites = []
    distinct_site_names.each do |site_name|
      site = Site.find_by_sitename(site_name)
      if site.nil?
        raise "Site #{site_name} is not in the database."
      end
      upload_sites << site
    end
    upload_sites
  end

  # Returns the list of Species used by the data set, or the Species specified
  # globally if site information was not included in the upload file.  Raises a
  # RuntimeError no match is found for some site in the data set.  Used by the
  # +confirm_data+ action and as a helper method for +get_upload_cultivars+.
  def get_upload_species
    @data.rewind

    species_names = []
    if @headers.include?("species")
      @data.each do |row|
        species_names << row["species"]
      end
    else
      global_species = @session[:global_values][:species]
      if global_species.empty?
        raise "Species name can't be blank"
      end
      species_names << global_species
    end
    distinct_species_names = species_names.uniq
    upload_species = []
    distinct_species_names.each do |species_name|
      species = Specie.find_by_scientificname(species_name)
      if species.nil?
        raise "Species #{species_name} is not in the database."
      end
      upload_species << species
    end
    upload_species
  end

  # Returns the list of Cultivars used by the data set, or the Cultivar
  # specified globally if site information was not included in the upload file.
  # Raises a RuntimeError no match is found for some site in the data set.  Used
  # by the +confirm_data+ action.
  def get_upload_cultivars
    @data.rewind

    cultivars = []
    if @headers.include?("cultivar")
      @data.each do |row|
        cultivar_name = row["cultivar"]
        if !cultivar_name.nil? and !cultivar_name.strip.empty?
          # We can do this since (for now at least) we require a species field if there is a cultivar field:
          cultivars << { cultivar_name: row["cultivar"], species_name: row["species"] }
        end
      end
    else
      upload_species = get_upload_species
      globally_specified_cultivar = @session[:global_values][:cultivar]
      if !globally_specified_cultivar.empty?
        if upload_species.size == 1
          global_cultivar = { cultivar_name: globally_specified_cultivar, species_name: upload_species[0].scientificname }
          cultivars << global_cultivar
        else
          raise "If you specify the cultivar globally, you can only have one species in your data set."
        end
      end
    end
    distinct_cultivars = cultivars.uniq
    upload_cultivars = []
    distinct_cultivars.each do |cultivar_info|
      cultivar = Cultivar.joins("JOIN species ON species.id = cultivars.specie_id").where("cultivars.name = :cultivar_name AND species.scientificname = :species_name", cultivar_info).first
      if cultivar.nil?
        raise "Cultivar #{cultivar_info[:cultivar_name]} associated with species #{cultivar_info[:species_name]} is not in the database."
      end
      upload_cultivars << { cultivar: cultivar, species_name: cultivar_info[:species_name] }
    end
    upload_cultivars
  end

  # Returns the list of Citations used by the data set, or the Citation specified
  # globally if site information was not included in the upload file.  Raises a
  # RuntimeError no match is found for some site in the data set.  Used by the
  # +confirm_data+ action.
  def get_upload_citations
    @data.rewind

    # all validation has been done already at this point
    citation_id_list = @session[:citation_id_list] || [ @session[:citation] ]
    upload_citations = []
    citation_id_list.each do |citation_id|
      citation = Citation.find_by_id(citation_id)
      upload_citations << citation
    end
    upload_citations
  end

  # Returns the list of Treatments used by the data set, or the Treatment
  # specified globally if site information was not included in the upload file.
  # Raises a RuntimeError no match is found for some site in the data set.  Used
  # by the +confirm_data+ action.
  def get_upload_treatments
    @data.rewind

    treatment_names = []
    if @headers.include?("treatment")
      @data.each do |row|
        treatment_names << row["treatment"]
      end
    else
      global_treatment = @session[:global_values][:treatment]
      if global_treatment.empty?
        raise "Treatment name can't be blank"
      end
      treatment_names << global_treatment
    end
    distinct_treatment_names = treatment_names.uniq
    upload_treatments = []
    distinct_treatment_names.each do |treatment_name|
      treatment = Treatment.find_by_name(treatment_name)
      if treatment.nil?
        raise "Treatment #{treatment_name} is not in the database."
      end
      upload_treatments << treatment
    end
    upload_treatments
  end

  def insert_data
    insertion_data = get_insertion_data

    if yield_data?
      Yield.transaction do
        insertion_data.each do |row|
          Yield.create!(row)
        end
      end
    else
      result = Trait.transaction do
        current_entity_id = nil
        insertion_data.each do |row|
          if row[:new_entity]
            e = Entity.create!
            current_entity_id = e.id
            row.delete(:new_entity)
          end
          row[:entity_id] = current_entity_id
          covariate_info = row.delete("covariate_info")
          t = Trait.create!(row)
          covariate_info.each do |covariate_attributes|
            covariate_attributes[:trait_id] = t.id
            Covariate.create!(covariate_attributes)
          end # covariate_info.each
        end # insertion_data.each
      end # Trait.transaction
    end # if-else
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

  # Using the trait_covariate_associations table and the column headings in the
  # upload file, find relevant information about the trait and covariate
  # variables for this upload.
  def get_trait_and_covariate_info

    # A list of TraitCovariateAssociation objects corresponding to trait
    # variable names occurring in the heading.
    relevant_associations = TraitCovariateAssociation.all.select { |a| @headers.include?(a.trait_variable.name) }

    # A list of recognized trait variable names in the heading; a trait variable
    # is recognized only if it is in the trait_covariate_associations table
    @traits_in_heading = relevant_associations.collect { |a| a.trait_variable.name }.uniq

    # A list of Variable objects corresponding to all the covariates required by
    # the set of trait variables in the data set.
    @required_covariates = relevant_associations.select { |a| a.required }.collect { |a| a.covariate_variable }.uniq

    # A list of variable names corresponding to all the covariates associated
    # with some member of the set of trait variables in the data set--in other
    # words, these are names of variables that will be recognized should they
    # occur in the heading.
    @allowed_covariates = relevant_associations.collect { |a| a.covariate_variable.name }.uniq
  end

  # Using the trait_covariate_associations table and the column headings in the
  # upload file, construct a hash whose keys are the the ids of the trait
  # variables occurring in the data set and whose values give the variable name
  # and the associated covariates that occur in the data set.
  #
  # ===Example
  # {
  #   15: {
  #         name: "SLA",
  #         covariates: {
  #                       "canopy_layer" => 80
  #                     }
  #       },
  #    4: {
  #         name: "Vcmax",
  #         covariates: {
  #                       "canopy_layer" => 80,
  #                       "leafT" => 81
  #                     }
  #       }
  # }
  def get_variables_in_heading

    # A list of TraitCovariateAssociation objects corresponding to trait
    # variable names occurring in the heading.
    relevant_associations = TraitCovariateAssociation.all.select { |a| @headers.include?(a.trait_variable.name) }
    trait_variables = relevant_associations.collect { |a| a.trait_variable }.uniq

    @heading_variable_info = {}

    trait_variables.each do |tv|
      covariates = relevant_associations.select { |a| a.trait_variable_id = tv.id && @headers.include?(a.covariate_variable.name) }.collect { |a| a.covariate_variable }
      covariate_hash = {}
      covariates.each do |c|
        covariate_hash[c.name] = c.id
      end
      @heading_variable_info[tv.id] = { name: tv.name, covariates: covariate_hash }
    end

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
        citation_id = nil
        if id_values["citation_id"]
          # We are looking at a row of the CSV file and both the
          # citation information and the treatment information are in
          # the file.
          citation_id = id_values["citation_id"]
        elsif !@session[:citation].nil?
          # The citation was specified globally.
          citation_id = @session[:citation]
        else
          # We are looking up the treatment id for a
          # globally-specified treatment name, but the citation
          # information is in the CSV file.
          citation_id = @session[:citation_id_list][0]
        end

        treatment = existing_treatment?(value, citation_id)
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

  # Uses the global data values specified interactively by the user to
  # convert @data to an Array of Hashes suitable for inserting into
  # the traits table.  Used by the +insert_data+ action.
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
    if trait_data?
      get_variables_in_heading # sets @heading_variable_info
    end
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

      if csv_row_as_hash.has_key?("SE")
        # apply rounding to the standard error
        rounded_se = number_with_precision(csv_row_as_hash["SE"].to_f, precision: @session["rounding"]["SE"].to_i, significant: true)

        # In the yields table, the standard error is stored in the "stat" column:
        csv_row_as_hash["stat"] = rounded_se
        # The statname should be set to "SE":
        csv_row_as_hash["statname"] = "SE"
      end

      yield_columns = Yield.columns.collect { |column| column.name }
      trait_columns = Trait.columns.collect { |column| column.name }

      if yield_data?
        add_yield_specific_attributes(csv_row_as_hash)
        # eliminate extraneous data from CSV row
        csv_row_as_hash.keep_if do |key, value|
          yield_columns.include?(key)
        end
        @mapped_data << csv_row_as_hash
      elsif trait_data?
        new_entity = true
        @heading_variable_info.each_key do |trait_variable_id|

          # we have to be more careful than for yields since we may use the row for multiple trait rows
          row_data = csv_row_as_hash.clone

          if new_entity
            row_data[:new_entity] = true
            new_entity = false
          end

          add_trait_specific_attributes(row_data, trait_variable_id)

          row_data.keep_if do |key, value|
            trait_columns.include?(key) || key == "covariate_info" || key == :new_entity
          end

          @mapped_data << row_data
        end
      end

    end

    @mapped_data
  end

  def add_yield_specific_attributes(csv_row_as_hash)

    # apply rounding to the yield
    rounded_yield = number_with_precision(csv_row_as_hash["yield"].to_f, precision: @session["rounding"]["vars"].to_i, significant: true)

    # In the yields table, the yield is stored in the "mean" column:
    csv_row_as_hash["mean"] = rounded_yield

  end

  def add_trait_specific_attributes(row_data, trait_variable_id)

    associated_trait_info = @heading_variable_info[trait_variable_id]

    row_data["variable_id"] = trait_variable_id

    # store covariate information in a temporary key:
    row_data["covariate_info"] = []
    # for each covariate belonging to this trait variable
    associated_trait_info[:covariates].each do |name, id|
      row_data["covariate_info"] << { variable_id: id, level: row_data[name].to_f }
    end
    # apply rounding to the trait variable value
    rounded_mean = number_with_precision(row_data[associated_trait_info[:name]].to_f, precision: @session["rounding"]["vars"].to_i, significant: true)

    # In the yields table, the yield is stored in the "mean" column:
    row_data["mean"] = rounded_mean

  end


end
