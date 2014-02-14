module BulkUploadHelper
  INTERACTIVE_COLUMNS = %w{site species treatment access_level cultivar date}

  def need_interactively_specified_data
    missing_columns = INTERACTIVE_COLUMNS - @headers
  end

  def need_citation_selection
    @headers.select { |field| field =~ /citation_/ }.empty? && session['citation'].nil?
  end

  ERROR_MESSAGE_MAP = {
    negative_yield: "Negative value for yield",
    unparsable_yield: "Yield value can't be parsed as a number",
    unresolvable_citation_reference: "Unresolvable citation reference",
    future_citation_year: "Citation year is in the future",
    too_old_citation_year: "Citation year is too far in the past",
    unparsable_citation_year: "Citation year can't be parsed as an integer",
    unresolvable_site_reference: "Unresolvable site reference",
    unresolvable_species_reference: "Unresovable species reference",
    unresolvable_treatment_reference: "Unresolvable treatment reference",
    unparsable_access_level: "Access level can't be parsed as an integer",
    unresolvable_cultivar_reference: "Unresolvable cultivar reference",
    unacceptable_date_format: "Unacceptable date format",
    future_date: "Date is in the future",
    invalid_date: "Date is invalid",
    invalid_sample_size: "Invalid sample size (n)",
    unparsable_sample_size: "Sample size (n) can't be parsed as an integer",
    unparsable_standard_error_value: "Standard error value (SE) can't be parsed as a number"
  }

  def make_validation_summary
    summary = "" # default to empty string if no errors
    if @file_has_fatal_errors
      
      summary = content_tag :div, id: "error_explanation", style: "width:850px; margin: auto" do
        contents = content_tag :div, "Your file contains #{pluralize(@total_error_count, "error")}.", class: "fade in alert alert-error centered"
        if @field_list_error_count > 0
          contents += content_tag :h2, "Field List Errors"

          contents += content_tag :ul do
            list_items = "".html_safe
            @validation_summary[:field_list_errors].each do |message|
              list_items += content_tag :li, "* " + message
            end
            list_items
          end # content_tag :ul
        end # if @field_list_error_count > 0

        if @data_value_error_count > 0
          contents += content_tag :h2, "Data Value Errors"

          contents += content_tag :ul do
            list_items = "".html_safe
            @validation_summary.each_pair do |key, value|
              if ERROR_MESSAGE_MAP.has_key?(key)
                list_items += content_tag :li, "* " + ERROR_MESSAGE_MAP[key] + " in these rows: " + value.join(', ')
              end # if .. has_key?
            end # each_pair do
            list_items
          end # content_tag :ul
        end # if @data_value_error_count > 0

        contents
      end # content_tag :div

    end # if @file_has_fatal_errors
    return summary
  end

  def make_warning_summary
    summary = "" # default to empty string if no warnings
    if  @csv_warnings.any?
      summary = content_tag :div, id: "warning_explanation", style: "width:850px; margin:auto" do
        div_content = content_tag :h2, "Warnings"
        div_content += content_tag :ul do
          list_items = "".html_safe
          @csv_warnings.each do |msg|
            list_items += content_tag :li, raw("* #{msg}") # use raw because msg may contain markup
          end
          list_items
        end
        div_content
      end
    end
    return summary
  end

  # Use the database column name to decide what to use as the source
  # for the column value.  This will either be: (1) A fixed value; (2)
  # A user-entered uniform value for all rows; (3) A value obtained
  # from a column in the CSV input file.
  def default_source_for(column_object)
    # convenience variables
    headers = @headers
    column = column_object.name

    case column
    when /(.+)_id/,  "date", "dateloc", "time", "timeloc", "access_level"
      if headers.include?(column)
        # If the database column name exactly matches the CSV heading, use that as the source column.
        use = "the value of this CSV column:</td><td class='column_name'>#{column} #{hidden_field_tag("mapping[source_column][#{column}]", column)}"
      else
        if column == "specie_id" && 
            (headers.include?("scientificname") || headers.include?("species.scientificname"))
          use = "the id for the row in the species table corresponding to the value of CSV column:</td><td class='column_name'>" + (headers.include?("species.scientificname") ? "species.scientificname" : "scientificname") + " #{hidden_field_tag("mapping[source_column][#{column}]", column)}"
        elsif column == "access_level"
          use = "this user-supplied value:</td><td>#{select_tag("mapping[value][#{column.to_sym}]", options_for_select([ ["1. Restricted", 1], ["2. Internal EBI & Collaborators", 2], ["3. External Researcher", 3], ["4. Public", 4]], 4))}"
        else
          use = "this user-supplied value:</td><td>#{text_field_tag ("mapping[value][#{column.to_sym}]"), nil, placeholder: "DEFAULT: #{column_object.default.nil? ? "NULL" : column_object.default }" }"
        end
      end

    when /date_(.+)/
      if headers.include?(column)
        use = "the value of CSV column:</td><td class='column_name'>#{column} #{hidden_field_tag("mapping[source_column][#{column}]", column)}"
      elsif headers.include?("date")
        use = "the value of SQL #{$1.upcase} function applied to CSV column</td><td class='column_name'>date"
      else
        use = "this user-supplied value:</td><td>#{text_field_tag ("mapping[value][#{column.to_sym}]"), nil, placeholder: "DEFAULT: #{column_object.default.nil? ? "NULL" : column_object.default }" }"
      end


    when /time_(.+)/
      if headers.include?(column)
        use = "the value of CSV column:</td><td class='column_name'>#{column} #{hidden_field_tag("mapping[source_column][#{column}]", column)}"
      elsif headers.include?("time")
        use = "the value of SQL #{$1.upcase} function applied to CSV column</td><td class='column_name'>time"
      else
        use = "this user-supplied value:</td><td>#{text_field_tag ("mapping[value][#{column.to_sym}]"), nil, placeholder: "DEFAULT: #{column_object.default.nil? ? "NULL" : column_object.default }" }"
      end

      
    when "checked"
      use = "always use</td><td>0 #{hidden_field_tag("mapping[source_column][#{column}]", 0)}"

    when "mean", "stat", "statname", "n"
      if headers.include?(column)
        use = "the value of CSV column:</td><td class='column_name'>#{column} #{hidden_field_tag("mapping[source_column][#{column}]", column)}"
        if ["mean", "stat"].include?(column)
          use += "</td><td>rounded to</td><td>#{select_tag("mapping[rounding][#{column}]", options_for_select([['0', 0], ['1', 1], ['2', 2], ['3', 3], ['4', 4]], '4')) }</td><td>places"
        end
      else
        use = "database default</td><td>#{column_object.default || "NULL"}"
      end

    when "notes"
      if headers.include?(column)
        use = "the value of CSV column:</td><td class='column_name'>#{column} #{hidden_field_tag("mapping[source_column][#{column}]", column)}"
      else
        use = "</td><td>(leave blank) #{hidden_field_tag("mapping[source_column][#{column}]", "")}"
      end
      
    else
      use = "DEFAULT"
    end # case column
    use
  end # default_source_for

=begin

  def source(dbcolumn)
    @headers = session[:headers]
    #raw(@headers.include?(dbcolumn.name) ? dbcolumn.name + "</td><td>"  : "---</td><td>" + (dbcolumn.default.nil? ? "NULL" : dbcolumn.default).to_s)

    @headers.include?(dbcolumn.name) ? dbcolumn.name : "default"
  end

  def options(dbcolumn)
    @headers = session[:headers]
    options = @headers.map do |heading|
      [heading, heading]
    end
    options << ["Database Default", "default"]
    [options, source(dbcolumn)]
  end

  def mapper_options(dbcolumn)
    options = []
    default = nil
    case dbcolumn.type
      when :decimal
      options << ["Parse as float and round", "round"]
      default = 'round'
      when :string, :text
      options << ["trim whitespace", "trim"]
      default = 'trim'
      when :integer
      options << ["Parse as Integer", 'to_i']
      if dbcolumn.name =~ /_id$/
        options << ["Look up id", 'lookup']
        default = 'lookup'
      end
    end
    if !session[:headers].include?(dbcolumn.name)
      options << ["Constant", "constant"]
      default = "constant"
    end
    [options, default]
  end

  def validation2class(value)
    if m = value[0].match(/(\w+)_id/)
      table_name = m[1]
      count = (eval table_name.classify).where("id = ?", value[1]).count
      count == 1 ? "green" : "red"
    else
      ""
    end
  end

  def lookup_value(value)
    if m = value[0].match(/(\w+)_id/)
      table_name = m[1]
      result = (eval table_name.classify).where("id = ?", value[1])
      if result.count == 1
        result = result.first
      else
        return "?"
      end
      
      case table_name
      when "site"
        return "<br>(#{result.sitename}&mdash;#{result.city}, #{result.state})"
      when "specie"
        return "<br>(#{result.scientificname})"
      when "citation"
        return "<br>(#{result.author}, #{result.year})"
      when "cultivar"
        return "<br>(#{result.name})"
      when "treatment"
        return "<br>(#{result.name})"
      when "variable"
        return "<br>(#{result.description})"
      when "user"
        return "<br>(#{result.name}, #{result.email})"
      when "entity"
        return result.name ? "<br>(#{result.name})" : ""
      when "method"
        return "<br>(#{result.name})"
      end
      return table_name
    end
    ""
  end

=end

  def validate(column, value)
    return "no_validation" if value.nil? || value.to_s.empty? || value == "NULL"

    if column.match(/_id$/)
      tablename = column.sub(/_id$/, '').classify
      if tablename == "Method"
        tablename = "Methods"
      end
      table = tablename.constantize
      if table.find_by_id(value)
        "found"
      else
        @errors = true
        "not_found"
      end
    else
      "no_validation"
    end
  end


end
