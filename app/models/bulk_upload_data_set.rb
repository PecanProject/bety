module ValidationResult
  attr :result, :message, :summary_message
  def initialize(result = nil, message = nil, summary_message = message, remedy_link = nil, row = nil)
    @result = result
    @message = message
    @summary_message = summary_message
    # to do: eliminate or start to utilize these instance variables:
    @remedy_link = remedy_link
    @row = row
  end
  def result_css_class
    category.to_s
  end
  def category
    case @result
    when :valid, :ignored, :non_unique_referent, :missing_referent, \
          :unacceptable_date_format, :invalid_date
      @result
    when :inconsistent_citation_and_site, :inconsistent_citation_and_treatment
      :inconsistent_correlatives
    when :negative_yield, :out_of_range_value, :future_citation_year, \
          :too_old_citation_year, :out_of_bounds_access_level, :future_date, \
          :invalid_sample_size, :out_of_range_value
      :out_of_bounds
    when :unparsable_yield, :unparsable_citation_year, \
          :unparsable_access_level, :unparsable_sample_size, \
          :unparsable_standard_error_value, :unparsable_number
      :unparsable_number
    else # in case we forgot anything
      @result
    end
  end
end

class Valid
  include ValidationResult
  def initialize
    super(:valid, "")
  end
end

class Ignored
  include ValidationResult
  def initialize
    super(:ignored, "This column will be ignored.")
  end
end

class BulkUploadDataException < StandardError
  include ValidationResult
end

class InconsistentCitationAndSiteException < BulkUploadDataException
  def initialize
    super(:inconsistent_citation_and_site, "Site is inconsistent with citation")
  end
end

class InconsistentCitationAndTreatmentException < BulkUploadDataException
  def initialize
    super(:inconsistent_citation_and_treatment, "Treatment is inconsistent with citation")
  end
end


class UnresolvableReferenceException < BulkUploadDataException
end

class NonUniquenessException < UnresolvableReferenceException
  def initialize(model_class_or_relation = nil, match_column_name = '', raw_value = '', table_entity_name = '')
    super(:non_unique_referent, "More than one row in the #{table_entity_name.pluralize} table matches this string", "Multiple matching referents")
  end
end

class MissingReferenceException < UnresolvableReferenceException
  def initialize(model_class_or_relation = nil, match_column_name = '', raw_value = '', table_entity_name = '')
    super(:missing_referent, "Not found in #{table_entity_name.pluralize} table", "Unresolvable #{table_entity_name} reference")
  end
end

class MissingCorrelativeException < UnresolvableReferenceException
  def initialize(model_class_or_relation = nil, match_column_name = '', raw_value = '', table_entity_name = '')
    super(:missing_correlative, "Can't resolve reference because of missing correlative #{table_entity_name.pluralize}")
  end
end

class InvalidCitationYearException < BulkUploadDataException
end

class UnparsableYieldException < BulkUploadDataException
  def initialize
    super(:unparsable_yield, "Not a valid number", "Unparsable yield value")
  end
end

class NegativeYieldException < BulkUploadDataException
  def initialize
    super(:negative_yield, "Yield can't be less than zero", "Negative value for yield")
  end
end

class UnparsableCitationYearException < BulkUploadDataException
  def initialize
    super(:unparsable_citation_year, "Not a valid integer", "Citation year can't be parsed as a number")
  end
end

class FutureCitationYearException < BulkUploadDataException
  def initialize
    super(:future_citation_year, "Citation year is in the future")
  end
end

class TooOldCitationYearException < BulkUploadDataException
  def initialize
    super(:too_old_citation_year, "Citation year is too far in the past")
  end
end

class UnparsableAccessLevelException < BulkUploadDataException
  def initialize
    super(:unparsable_access_level, "Not a valid integer", "Access level can't be parsed as an integer")
  end
end

class InvalidAccessLevelException < BulkUploadDataException
  def initialize
    super(:out_of_bounds_access_level, "access_level must be 1, 2, 3, or 4", "Out of bounds access level")
  end
end

class UnacceptableDateFormatException < BulkUploadDataException
  def initialize
    super(:unacceptable_date_format, "Dates must be in the form 1999-01-01", "Unacceptable date format")
  end
end

class InvalidDateException < BulkUploadDataException
  def initialize
    super(:invalid_date, "Invalid date", "Date is invalid")
  end
end

class FutureDateException < BulkUploadDataException
  def initialize
    super(:future_date, "Date is in the future")
  end
end

class UnparsableSampleSizeException < BulkUploadDataException
  def initialize
    super(:unparsable_sample_size, "Invalid integer", "Sample size can't be parsed as an integer")
  end
end

class InvalidSampleSizeException < BulkUploadDataException
  def initialize
    super(:invalid_sample_size, "n must be at least 2", "Invalid sample size (n)")
  end
end

class UnparsableStandardErrorValueException < BulkUploadDataException
  def initialize
    super(:unparsable_standard_error_value, "Not a valid number", "Standard error value (SE) can't be parsed as a number")
  end
end

class UnparseableVariableValueException < BulkUploadDataException
  def initialize
    super(:unparsable_number, "Not a valid number", "Variable value can't be parsed as a number")
  end
end

class OutOfRangeVariableException < BulkUploadDataException
  def initialize(message = '')
    super(:out_of_range_value, "Variable out of range.  #{message}", "Out-of-range variable value")
  end
end


class BulkUploadDataSet
  include ActionView::Helpers::NumberHelper # for rounding

  # An Array consisting of the (normalized) headers of the uploaded CSV file.
  # Normalization strips leading and trailing whitespace and for headings
  # matching one of the RECOGNIZED_COLUMNS, the heading is folded to the
  # canonical case. This is set upon instantiation.
  attr :headers

  # A list containing one item for each row of the input file (excluding the
  # heading row).  Each item is itself a list of hashes, one hash for each
  # column of the row.  Each hash has these keys:
  # fieldname::
  #
  #   The field name for the corresponding value (as given by the heading)
  #
  # data::
  #   The value itself, except with nil values normalized to the empty string
  #
  # During validation, this key is added:
  #
  # validation_result::
  #
  #   This will always be an object of some class that includes the
  #   ValidationResult module--that is, an instance of Valid, Ignored, or some
  #   subclass of BulkUploadDataException.
  #
  #   Set by +validate_csv_data+ and used by the
  #   +display_csv_data+ template.
  #
  # ==== Example
  #  [
  #   [
  #    {
  #      :fieldname=>"yield",
  #      :data=>"1",
  #      :validation_result=>#<Valid:0x007fd7db54c940
  #                                  @result=:valid,
  #                                  @message="",
  #                                  @summary_message="",
  #                                  ...>
  #    },
  #    {
  #      :fieldname=>"date",
  #      :data=>"2001-13-11",
  #      :validation_result=>#<InvalidDateException: InvalidDateException>
  #    }
  #   ],
  #   [
  #    {
  #      :fieldname=>"yield",
  #      :data=>"2",
  #      :validation_result=>#<Valid:0x007fd7db54bfb8
  #                                  @result=:valid,
  #                                  @message="",
  #                                  @summary_message="",
  #                                  ...>
  #    },
  #    {
  #      :fieldname=>"date",
  #      :data=>"11/6/2000",
  #      :validation_result=>#<UnacceptableDateFormatException: UnacceptableDateFormatException>
  #    }
  #   ],
  #   [
  #    {
  #      :fieldname=>"yield",
  #      :data=>"3",
  #      :validation_result=>#<Valid:0x007fd7db54b608
  #                                  @result=:valid,
  #                                  @message="",
  #                                  @summary_message="",
  #                                  ...>
  #    },
  #    {
  #      :fieldname=>"date",
  #      :data=>"2050-10-11",
  #      :validation_result=>#<FutureDateException: FutureDateException>
  #    }
  #   ]
  #  ]
  #
  attr :validated_data

  # Once initialized by +check_header_list+, this is Hash object containing a
  # summary of validation results.  One key, +:field_list_errors+, contains
  # information about all the errors having to do with the header list.  This
  # key is added and its value is set in +check_header_list+.  In addition, the
  # data validation process of method +validate_csv_data+ adds a key for each
  # type of error found (classified by the summary error message), and the value
  # of each such key consists of a hash with two keys: +:row_numbers+, whose
  # value is a list of row numbers where the corresponding error was found; and
  # +:css_class+, whose value is a CSS stylesheet class to assign to the HTML
  # element containing the summary message.
  #
  # ==== Example
  #  {
  #    :field_list_errors=>['In your CSV file, you must either have a "yield" column or you must have a column that matches the name of acceptable trait variable.'],
  #    ""Date is invalid"=>{
  #      :row_numbers=>[1],
  #      :css_class=>"invalid_date"
  #    },
  #    "Unacceptable date format"=>{
  #      :row_numbers=>[2],
  #      :css_class=>"unacceptable_date_format"
  #    },
  #    "Date is in the future"=>{
  #      :row_numbers=>[3],
  #      :css_class=>"out_of_bounds"
  #    }
  #  }
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
    end
    
    if @headers.include?('citation_doi') || (@headers.include?('citation_author') && @headers.include?('citation_year') && @headers.include?('citation_title'))
      # The file contains (sufficient) citation information, so make a list to keep track of referenced citations:
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
  #REQUIRED_DATE_FORMAT = /^(?<year>\d\d\d\d)(-(?<month>\d\d)(-(?<day>\d\d))?)?$/
  REQUIRED_DATE_FORMAT = /^(?<year>\d\d\d\d)-(?<month>\d\d)-(?<day>\d\d)$/

  # Given a CSV object (vis. "@data") whose lineno attribute equals 0, validate
  # the data it contains and store the results by setting the following
  # attributes:
  #     @validation_summary:
  #         Contains information about what types of data errors were found and
  #         the rows in which each type of error was found.
  #     @validated_data:
  #         An array of arrays of hashes, one hash for each data item of the
  #         input file.  Each hash has
  #         these keys:
  #             fieldname: The field name for the corresponding value
  #                 (as given by the heading, but normalized)
  #             data: The value itself, except with nil values
  #                 normalized to the empty string
  #             validation_result: This will always be an object of some class
  #                 that includes the ValidationResult module--that is, an
  #                 instance of Valid, Ignored, or some subclass of
  #                 BulkUploadDataException.
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
      validated_row = row.collect { |value| { fieldname: value[0], data: value[1], validation_result: Valid.new } }
      @validated_data << validated_row
    end

    @validated_data.each_with_index do |row, i|
      row_number = i + 1

      # collect some data about the row as we do the validation
      # TO-DO: rename citation_id
      citation_id = nil
      matching_site = nil

      row.each do |column|

        begin

          column[:data] ||= ""

          case column[:fieldname]

          when "yield"

            begin
              # yield is a keyword; hence "amount_of_yield"
              amount_of_yield = Float(column[:data])
            rescue ArgumentError => e
              raise UnparsableYieldException
            else
              if amount_of_yield < 0
                raise NegativeYieldException
              end
            end

          when "citation_doi"

            citation_id = doi_of_existing_citation?(column[:data])

          when "citation_author"

            # accept anything for now

          when "citation_year"

            begin
              year = Integer(column[:data])
            rescue ArgumentError => e
              raise UnparsableCitationYearException
            else
              if year > Date.today.next_year.year
                raise FutureCitationYearException
              elsif year < 1436
                raise TooOldCitationYearException
              end
            end

          when "citation_title"

            # accept anything for now

          when "site"

            matching_site = existing_site?(column[:data])

          when "species"

            existing_species?(column[:data])

          when "access_level"

            begin
              access_level = Integer(column[:data])
            rescue ArgumentError => e
              raise UnparsableAccessLevelException
            else
              if !(1..4).include? access_level
                raise InvalidAccessLevelException
              end
            end

          when "cultivar"

            if !column[:data].strip.empty? # cultivar is optional!
              begin
                existing_cultivar?(column[:data])
              rescue NonUniquenessException
                # We only care that cultivar names are unique per species.
              end

              # If we get here, the culitvar name is valid, but we still have to check consistency.

              # We need the species id to validation this:
              species_index = row.index { |h| h[:fieldname] == "species" }

              begin
                species_id = existing_species?(row[species_index][:data])
              rescue
                raise MissingCorrelativeException
              else
                existing_cultivar?(column[:data], species_id)
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
              raise UnacceptableDateFormatException
            else
              # Make sure it's a valid date
              begin
                date = Date.new(year.to_i, month.to_i, day.to_i)
              rescue ArgumentError => e
                raise InvalidDateException #"year: #{year}; month: #{month}; day: #{day}"
              else
                # Date is valid; but make sure the range is reasonable

                if date > Date.today
                  raise FutureDateException
                end
              end
            end

          when "n"

            begin
              n = Integer(column[:data])
            rescue ArgumentError => e
              raise UnparsableSampleSizeException
            else
              if n <= 1
                raise InvalidSampleSizeException
              end
            end

          when "SE"

            begin
              Float(column[:data])
            rescue ArgumentError => e
              raise UnparsableStandardErrorValueException
            end

          when "notes"

            # accept anything for now

          when "treatment"

            # This is ignored for now until we have the citation information.

          else # either a trait or covariate variable name or will be ignored

            if trait_data?
              get_trait_and_covariate_info
            end
            if trait_data? && (@traits_in_heading + @allowed_covariates).include?(column[:fieldname])
              column[:validation_result] = Valid.new # reset below if we find otherwise

              begin
                value = Float(column[:data])
              rescue ArgumentError => e
                raise UnparsableVariableValueException
              else

                v = Variable.find_by_name(column[:fieldname])

                if !v.min.nil? and value < v.min.to_f
                  raise OutOfRangeVariableException, "The value of the #{v.name} trait must be at least #{v.min} #{v.units}."
                end

                if !v.max.nil? and value > v.max.to_f
                  raise OutOfRangeVariableException, "The value of the #{v.name} trait must be at most #{v.max} #{v.units}."
                end
              end

            else
              column[:validation_result] = Ignored.new
            end

          end # case

        rescue BulkUploadDataException => e
          column[:validation_result] = e
          add_to_validation_summary(e, row_number)
        end

      end # row.each

      # validation of citation information by author, year, and date
      # happens outside the case statement since it involves
      # multiple columns

      if @headers.include?('citation_author') && @headers.include?('citation_year') && @headers.include?('citation_title')

        author_index = row.index { |h| h[:fieldname] == "citation_author" }
        year_index = row.index { |h| h[:fieldname] == "citation_year" }
        title_index = row.index { |h| h[:fieldname] == "citation_title" }
        begin
          citation_id = existing_citation(row[author_index][:data], row[year_index][:data], row[title_index][:data])
        rescue InvalidCitationYearException, UnresolvableReferenceException => e
          row[year_index][:validation_result] = e

          if e.is_a? InvalidCitationYearException
            e = UnresolvableReferenceException.new
          end

          row[author_index][:validation_result] = e
          row[title_index][:validation_result] = e

          # For purposes of the summary, count the citation error as an
          # unresolved reference, even if the year was invalid:
          add_to_validation_summary(e, row_number)

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
        if !matching_site.nil?
          if !citation.sites.include?(matching_site)
            site_index = row.index { |h| h[:fieldname] == "site" }

            e = InconsistentCitationAndSiteException.new

            row[site_index][:validation_result] = e
            add_to_validation_summary(e, row_number)
          end
        end

        # If a treatment was specified in this row, ensure that it is
        # consistent with the citation.
        treatment_index = row.index { |h| h[:fieldname] == "treatment" }
        if !treatment_index.nil?
          treatment = row[treatment_index][:data]

          begin
            existing_treatment?(treatment)
          rescue NonUniquenessException
            # We only care that treatment names are unique per citation.
          rescue UnresolvableReferenceException => e
            row[treatment_index][:validation_result] = e
            add_to_validation_summary(e, row_number)
          end

          # If we get here, the treatment name is valid, but we still have to check consistency.

          begin
            existing_treatment?(treatment, citation.id)
          rescue UnresolvableReferenceException
            e = InconsistentCitationAndTreatmentException.new

            row[treatment_index][:validation_result] = e
            add_to_validation_summary(e, row_number)
          end
        end

      end
    end # @validated_data.each

    @field_list_error_count = @validation_summary[:field_list_errors].size
    @data_value_error_count = (@validation_summary.keys - [ :field_list_errors ]).
      collect{|key| @validation_summary[key][:row_numbers].size}.reduce(:+) || 0 # || 0 "fixes" the case where there are no data value errors
    @total_error_count = @field_list_error_count + @data_value_error_count
    @file_has_fatal_errors = !@total_error_count.zero?

    @session[:number_of_rows] = @validated_data.size

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
        site_names << row["site"].downcase
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
      upload_sites <<  existing_site?(site_name)
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
        species_names << row["species"].downcase
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
      upload_species << existing_species?(species_name)
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
          # We can assume there is a "species" column since (for now at least) we require a species field if there is a cultivar field.
          cultivars << { cultivar_name: cultivar_name.downcase, species_name: row["species"].downcase }
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
      species = existing_species?(cultivar_info[:species_name])
      cultivar = existing_cultivar?(cultivar_info[:cultivar_name], species.id)
      upload_cultivars << { cultivar: cultivar, species_name: species.scientificname }
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

    treatments = []
    if @headers.include?("treatment")
      if @headers.include?("citation_doi")
        @data.each do |row|
          treatments << { treatment_name: row["treatment"].downcase, citation: doi_of_existing_citation?(row["citation_doi"]) }
        end
      elsif @headers.include?("citation_author")
        @data.each do |row|
          treatments << { treatment_name: row["treatment"].downcase, citation: existing_citation(row["citation_author"], row["citation_year"], row["citation_title"]) }
        end
      else
        @data.each do |row|
          treatments << { treatment_name: row["treatment"].downcase, citation: Citation.find(@session[:citation]) }
        end
      end
    else
      global_treatment = @session[:global_values][:treatment]
      if global_treatment.empty?
        raise "Treatment name can't be blank"
      end

      citation_id_list = @session[:citation_id_list] || [ @session[:citation] ]
      upload_citations = []
      citation_id_list.each do |citation_id|
        treatments << { treatment_name: global_treatment, citation: Citation.find_by_id(citation_id) }
      end
    end

    distinct_treatments = treatments.uniq
    upload_treatments = []
    distinct_treatments.each do |treatment|
      upload_treatments << { treatment: existing_treatment?(treatment[:treatment_name], treatment[:citation].id), associated_citation: treatment[:citation] }
    end
    upload_treatments
  end

  # Attempt to insert the data contained in the upload file into the appropriate
  # tables of the database in accordance with any interactively-specified values
  # and options the user may have chosen.
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

    # convert all headings to canonical form (strip whitespace and correct
    # capitalization)
    csv.header_convert { |h| normalize_heading(h) }

    # normalize whitespace in all data fields where whitespace is not
    # significant; keep case for display purposes--delay folding to lowercase
    csv.convert do |value, field_info|
      field_info[:header] == 'notes' ? value : value.squish
    end

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

  def normalize_heading(heading)
    heading = heading.to_s.strip

    if /SE/i.match heading
      heading.upcase
    elsif Regexp.new(RECOGNIZED_COLUMNS.join('|'), Regexp::IGNORECASE).match heading
      heading.downcase
    else
      heading
    end
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

  def sql_columnref_to_normlized_columnref(col, preserve_case = false)
    if !preserve_case
      col = "LOWER(#{col})"
    end
    "REGEXP_REPLACE(TRIM(FROM #{col}), ' +', ' ')"
  end

  def existing?(model_class_or_relation, match_column_name, raw_value, table_entity_name)
    matches = model_class_or_relation.where(["#{sql_columnref_to_normlized_columnref(match_column_name)} = :stored_value",
                                             { stored_value: raw_value.downcase }])
    if matches.size > 1
      raise NonUniquenessException.new(model_class_or_relation, match_column_name, raw_value, table_entity_name)
    elsif matches.size == 0
      raise MissingReferenceException.new(model_class_or_relation, match_column_name, raw_value, table_entity_name)
    end

    return matches[0]
  end

  def existing_species?(name)
    return existing?(Specie, "scientificname", name, "species")
  end

  def existing_site?(name)
    return existing?(Site, "sitename", name, "site")
  end

  def existing_treatment?(name, citation_id = nil)
    if citation_id.nil?
      # match against any treatment
      existing?(Treatment, "name", name, "treatment")
    else
      # only match against treatments belonging to given citation
      existing?(Citation.find(citation_id).treatments, "name", name, "treatment")
    end
  end

  def doi_of_existing_citation?(doi)
    return existing?(Citation, "doi", doi, "citation")
  end

  def existing_citation(author, year, title)
    begin
      Integer(year)
    rescue ArgumentError
      raise InvalidCitationYearException
    end

    c = Citation.where("#{sql_columnref_to_normlized_columnref("author")} = :author " +
                       "AND year = :year AND #{sql_columnref_to_normlized_columnref("title")} LIKE :title_matcher",
                       { author: author.downcase, year: year, title_matcher: "#{title.downcase}%" })

    if c.size > 1
      raise NonUniquenessException
    elsif c.size == 0
      raise MissingReferenceException
    else
      return c.first
    end
  end

  def existing_cultivar?(name, species_id = nil)
    if species_id.nil?
      existing?(Cultivar, "name", name, "cultivar")
    else
      existing?(Cultivar.where("specie_id = ?", species_id), "name", name, "cultivar")
    end
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

    # Get interactively-specified values, or set to empty hash if nil; since we
    # are going to alter interactively_specified_values, we use clone to make a
    # copy so that the session value remains as is.
    interactively_specified_values = @session["global_values"].clone rescue {}

    # TO DO: decide if this code serves any useful purpose:
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

  def add_to_validation_summary(e, row_number)
    key = e.summary_message
    if @validation_summary.has_key? key
      @validation_summary[key][:row_numbers] << row_number
    else
      @validation_summary[key] = {}
      @validation_summary[key][:row_numbers] = [ row_number ]
      # to-do: If different values of e have the same summary_message but different values for result_css_class, the class for the summary message may not match some of the classes for the cells the message refers to.  Resolve this.
      @validation_summary[key][:css_class] = e.result_css_class
    end
  end

  def yield_data?
    @is_yield_data
  end

  def trait_data?
    !@is_yield_data
  end

end
