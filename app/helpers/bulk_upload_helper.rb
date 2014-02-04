module BulkUploadHelper

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
      use = "always use</td><td>0"

    when "mean", "stat", "statname", "n"
      if headers.include?(column)
        use = "the value of CSV column:</td><td class='column_name'>#{column} #{hidden_field_tag("mapping[source_column][#{column}]", column)}</td><td>rounded to</td><td>#{select_tag("sd", options_for_select([['0', 0], ['1', 1], ['2', 2], ['3', 3], ['4', 4]])) }</td><td>places"
      else
        use = "database default</td><td>#{column_object.default || "NULL"}"
      end

    when "notes"
      if headers.include?(column)
        use = "the value of CSV column:</td><td class='column_name'>#{column} #{hidden_field_tag("mapping[source_column][#{column}]", column)}"
      else
        use = "</td><td>(leave blank)"
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
    return "gray" if value.nil? || value.empty?

    if column.match(/_id$/)
      table = column.sub(/_id$/, '').classify.constantize
      if table.find_by_id(value)
        "green"
      else
        "red"
      end
    else
      "green"
    end
  end


end
