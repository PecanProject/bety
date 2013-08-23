# A module to be used inside models to facilitate searching.  Since we
# want the advanced_search method to be a class method, use
#
# <tt>extend AdvancedSearch</tt>
#
# at the class level.
module AdvancedSearch

  # Given the string +search+, which will usually be one or more words
  # or parts of words, generates an array of the form
  #   [search_template, value1, value2, ... ]
  # that can be used as the argument to the ActiveRecord _where_
  # method.
  #
  # The effect of the generated condition is to select only rows in
  # which each (space-separated) term appearing in the string +search+
  # is a substring of the value in at least one of the columns
  # appearing in the constant +SEARCH_FIELDS+ (or in any column of the
  # table if +SEARCH_FIELDS+ is nil).
  #
  # For example, if +SEARCH_FIELDS+ consists of columns 'A' and 'B',
  # and the +search+ is the string "j k", then the generated condition
  # corresponds to the SQL WHERE clause
  #   WHERE (A LIKE '%j%' OR B LIKE '%j%') AND (A LIKE '%k%' OR B LIKE '%k%')
  # In other words, the WHERE clause is a conjunction of clauses, one
  # for each search term.  And each of these conjuncts is a
  # disjunction of LIKE conditions, one for each search field.
  #
  # A typical use of advanced_search is in ActiveRecord's +scope+
  # method:
  #   scope :search, lambda { |search| where(advanced_search(search)) }
  def advanced_search(search)
    words = search.split

    # default to all table columns if SEARCH_FIELDS is nil
    search_columns = (self::SEARCH_FIELDS || self.column_names)

    number_of_columns_to_search = search_columns.size

    # a conjunct for each word
    conjuncts = [ "(" +
                  search_columns.collect { |x| "#{x} LIKE ?" }
                    .compact
                    .join(" OR ") + ")" # a disjunction for each search column
                ] * words.length

    # join the conjunctions into a conjunction
    search_template = conjuncts.join(" AND ") 

    # generate the values for the search template; each search term is
    # surrounded by wildcard characters and must be repeated as many
    # times as there are columns to be searched
    value_array = words.collect { |word| [ '%' + word + '%'] * number_of_columns_to_search }.flatten

    [ search_template, value_array ].flatten

  end
end
