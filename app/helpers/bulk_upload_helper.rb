module BulkUploadHelper


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


end
