
# Add SEARCH_INCLUDES & SEARCH_FIELDS to your class to narrow the search scope
# Not adding them will search all fields in your class, but not other classes
# --Must include SEARCH_FIELDS if you want to search related classes using SEARCH_INCLUDES
# Searches entire day range (00:00 -> 23:59) when doing date searches
# 
# class MyClass
#   extend SimpleSearch
#   SEARCH_INCLUDES = %w{ other_class }
#   SEARCH_FIELDS = %{ id name other_class.name }
#   (...)
# end

module SimpleSearch
  def simple_search(search)
    if search and !search.empty?
      #date search
      begin
        #search.valid_date? *search.split(/[\/-]/).collect(&:to_i) 
        date = Date.parse(search) 
        date_search = [date - 1.day,date + 1.day]
      rescue
        date_search = [nil,nil]
      end
      [(self::SEARCH_FIELDS || self.column_names).collect { |x| type_query(x,search,date_search)}.compact.join(" or "), { :search => search, :wildcard_search => "%#{search}%", :date_start_search => date_search[0], :date_end_search => date_search[1] }]
#      find(:all,
#           :include => self::SEARCH_INCLUDES,
#           :conditions => [(self::SEARCH_FIELDS || self.column_names).collect { |x| type_query(x,search,date_search)}.compact.join(" or "), { :search => search, :wildcard_search => "%#{search}%", :date_start_search => date_search[0], :date_end_search => date_search[1] }])
    else
      {} 
      #find(:all) # Causes very slow sorting if not searching
    end
  end

  def api_search(params)
    conditions = {}
    select = []
    params.each do |k,v|
      next if !self.column_names.include?(k)
      conditions[k] = v
    end
    if params["filters"]
      params["filters"].each do |v|
        next if !self.column_names.include?(v)
        select << v
      end
    end
    select = ["*"] if select.empty?
    find(:all, :conditions => conditions, :select => select.join(","))
  end

  private

  def type_query(column,search,date_search)
    if column.split(".").length == 1
      type = self.columns_hash[column].type
    else
      column_split = column.split(".",2)
      type = (eval column_split.first.sub('species','specie').classify.sub('Method','Methods')).columns_hash[column_split.last].type
    end
    case type
    when :boolean
      search[/[10tfTF]/] == search ? "#{column} = :search" : nil
    when :datetime
      # Check to see if valid date in string, most of line is error catching.
      # If valid wrap in date range +- 1 day
       date_search == [nil,nil] ? nil : "(#{column} > :date_start_search and #{column} < :date_end_search)"
    when :integer
      search[/\d*/] == search ? "#{column} = :search" : nil
    else
      "#{column} like :wildcard_search"
    end
  end
end
