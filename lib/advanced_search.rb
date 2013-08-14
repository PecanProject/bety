

module AdvancedSearch
  def advanced_search(search)
    if search and !search.empty?

      words = search.split

      search_fields = (self::SEARCH_FIELDS || self.column_names)

      number_of_fields_to_search = search_fields.size

      

      conjuncts = [ "(" +
                    search_fields.collect { |x| "#{x} like ?" }
                      .compact
                      .join(" OR ") + ")"
                  ] * words.length

      search_template = conjuncts.join(" AND ") 

      value_array = words.collect { |word| [ '%' + word + '%'] * number_of_fields_to_search }.flatten

      logger.info(search_template)
      logger.info(value_array)

      [ search_template, value_array ].flatten

    else
      # .where({}) finds everything
      {}
    end
  end

end
