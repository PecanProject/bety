
# Add SEARCH_INCLUDES & SEARCH_FIELDS to your class to narrow the search scope.
#
# Not adding them will search all fields in your class, but not other classes.
# _Must_ include SEARCH_FIELDS if you want to search related classes using SEARCH_INCLUDES.
#
# Searches entire day range (00:00 -> 23:59) when doing date searches.
# 
# ==Usage
#   class MyClass
#     extend SimpleSearch
#     SEARCH_INCLUDES = %w{ other_class }
#     SEARCH_FIELDS = %{ id name other_class.name }
#     (...)
#   end

module SimpleSearch

  # simple_search turns a search string into an object usable as an
  # argument for an ActiveRecord '.where()' clause in one of the
  # following ways:
  #
  # * If the argument +search+ contains at least one <tt>=</tt> sign,
  #   the search string is assumed to be a comma-separated sequence of
  #   column-value specifications of the form <tt>column_name =
  #   value</tt>.  Each such specification in which the column is a
  #   column in <tt>self.column_names</tt> (or in which the column is
  #   one of the columns specified in the +SEARCH_FIELDS+ array, in
  #   the case where +self.column_names+ is +nil+, as might happen if
  #   this module is used in a class other than a model) is added as a
  #   key-value pair to the +conditions+ hash returned by this method.
  #
  # * Otherwise, if the +search+ does not contain a <tt>=</tt>
  #   character, a search-string template is created containing a
  #   clause of the form <tt>columnName like :wildcard_search</tt> for
  #   each column in <tt>self::SEARCH_FIELDS</tt> (or in
  #   +self.column_names+ if +SEARCH_FIELDS+ is nil) that is not of
  #   type _boolean_, _datetime_, or _integer_.  If the entire search
  #   string is a single character representing a boolean value--that
  #   is, either '1', '0', 't', 'T', 'f', or 'F', then a clause of the
  #   form <tt>columnName = :search</tt> is added for each column of
  #   type _boolean_.  If the entire search string consists of digits,
  #   then a clause of the form <tt>columnName = :search</tt> is added
  #   for each column of type _integer_.  Finally, if a date can be
  #   parsed out of the search string, a clause of the form
  #   <tt>(columnName > :date_start_search and columnName <
  #   :date_end_search)</tt> is added for each column of type
  #   _datetime_.  Finally, all these clauses are joined by " or ".
  #   The Hash object corresponding to the template has keys :search,
  #   :wildcard_search, :date_start_search, and :date_end_search whose
  #   corresponding values are the entire search string, the search
  #   string surrounded by '%' characters, a date one day before the
  #   date parsed out of the search string (or nil if none was found),
  #   and a date one day after the date parsed out of the search
  #   string (or nil), respectively.
  def simple_search(search)
    if search and !search.empty?
      #date search
      begin
        date = Date.parse(search) 
        date_search = [date - 1.day, date + 1.day]
      rescue
        date_search = [nil, nil]
      end
      if search[/=/]
        conditions = {}
        search.split(",").each do |_search|
          _search.strip!
          if (self.column_names || self::SEARCH_FIELDS).include?(_search.split("=", 2).first)
            conditions[_search.split("=", 2).first.strip.to_s] = _search.split("=", 2).last.strip.to_s
          end
        end
        # return a hash whose keys are column names and whose values are the required values of those columns
        conditions
      else
        # return an array of the form [format_string, HASH] suitable for using as the argument for '.where()'
        [
         (self::SEARCH_FIELDS || self.column_names).collect { |x| type_query(x, search, date_search) }
                                                   .compact
                                                   .join(" or "), 
         { :search => search, :wildcard_search => "%#{search}%", 
           :date_start_search => date_search[0], :date_end_search => date_search[1] }
        ]
      end
    else
      # .where({}) finds everything
      {}
    end
  end

  def api_search(params)
    conditions = {}
    select = []
    params.each do |k, v|
      next if !self.column_names.include?(k) && k !~ /\./
      conditions[k] = v
    end
    if params["filters"]
      params["filters"].each do |v|
        next if !self.column_names.include?(v)
        select << v
      end
    end
    params[:include] = [] unless params[:include]
    select = ["*"] if select.empty?
    # keep this debug line for now:
    Rails.logger.debug("where(#{conditions.inspect}).select(#{select.join(",").inspect}).includes(#{params[:include].inspect})")
    where(conditions).select(select.join(",")).includes(params[:include])
  end

  private

  def type_query(column, search, date_search)
    if column.split(".").length == 1
      type = self.columns_hash[column].type
    else
      column_split = column.split(".", 2)
      type = (eval column_split.first.sub('species', 'specie').classify
                .sub('Method', 'Methods').sub('Dbfile', 'DBFile'))
        .columns_hash[column_split.last].type
    end
    Rails.logger.debug("got here; column = #{column}; type = #{type}")
    case type
    when :boolean
      search[/[10tfTF]/] == search ? "#{column} = :search" : nil
    when :datetime, :date
      # Check to see if valid date in string, most of line is error catching.
      # If valid wrap in date range +- 1 day
       date_search == [nil, nil] ? nil : "(#{column} > :date_start_search and #{column} < :date_end_search)"
    when :integer
      search[/\d*/] == search ? "#{column} = :search" : nil
    when :decimal
# If we decide to do wildcard searches for decimal types, we need to do something like this to get it to work in PostgreSQL:
#      search[/[\.\d]*/] == search ? "CAST(#{column} AS TEXT) LIKE :wildcard_search" : nil
      search[/[\.\d]*/] == search ? "#{column} = :search" : nil
    when :float
      search[/(-?(\d+(\.\d*)?)|(\.\d+))([eE][+-]?\d\d?)?/] == search ? "#{column} = :search" : nil
    when :string, :text
      "LOWER(#{column}) LIKE LOWER(:wildcard_search)"
    when :timestamp
      # taking substring prevents, for example, a search on year "2002" from
      # matching a timestamp like "2014-09-03 21:38:16.012002"; for now,
      # restrict matching to the date portion of the timestamp
      "SUBSTRING(#{column}::text, 1, 10) LIKE :wildcard_search"
    else
      "#{column} like :wildcard_search"
    end
  end
end
