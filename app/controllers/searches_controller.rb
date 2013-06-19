# This controller handles searches.
include AuthenticatedSystem
class SearchesController < ApplicationController

  # This should be used on opening the home page ... before a user logs in
  # On attempting to login from this page ... feed it to the create method in this controller
  def index
#    @user.new = User.new
#    @session.new = Session.new

    search_string = params[:search]
    @search_type = params[:search_type] # "simple" or "advanced"

    if !search_string || search_string.strip == ""
      @results = []
    else

      search_terms = _parse_params

      # Construct the search condition string; this will have a
      # *conjunct* for each term (since *all* terms must be found); each
      # conjunct is a disjunction of three clauses--on for each column
      # we are searching.

      disjunct_clause = <<-CLAUSE
        (scientificname LIKE CONCAT('%', ?, '%')
          OR commonname LIKE CONCAT('%', ?, '%')
          OR treatment LIKE CONCAT('%', ?, '%'))
      CLAUSE

      # Make a clause for each search term:
      clause_array = [disjunct_clause] * search_terms.count
      # Join these by AND to make the full conjunction:
      search_condition = "result_type IN #{@search_domain} AND " + clause_array.join(' AND ')
      

      # We use each term three times, so duplicate them.
      search_terms.map! do |term|
        [term, term, term]
      end
      search_terms.flatten!

      @results = TraitsAndYieldsView.find(:all, 
                                          :conditions => [
                                                          search_condition,
                                                          search_terms
                                                         ].flatten!)

      respond_to do |format|
        format.html  # show html page as before
        format.csv do
          send_data result_to_csv(@results), :content_type => 'text/plain', :filename => 'search_results.csv'
        end
      end

    end

  end




  def result_to_csv(result)
    logger.info(result.class)


    if result.count == 0
      return ""
    end
    require 'csv'



    
    #keys = result[0].keys

    row = result[0]

=begin

    logger.info 'hi'
    logger.info(row.class)
    logger.info(row.class.superclass)
#    logger.info(row.class.included_modules.uniq.map {|a| a.to_s}.uniq.join("\n"))
    logger.info(row.public_methods.sort.join("\n"))
    logger.info(row.to_xml)


    csv_string = CSV.generate do |csv|
      result.each do |row|
        ar = []
        keys.each do |key|
          ar << row[key]
        end
      end
    end

=end

    csv_string = CSV.generate do |csv|
      csv << row.to_comma_headers

      result.each do |row|
        csv << row.to_comma
      end
    end

    logger.info(csv_string)

    return csv_string
  end

  # probably should be in a helper, but put here for now:
  #
  # Expects a list of search terms.  If the terms "yield" or "trait"
  # occur (in any case and in either singular or plural form) it
  # removes them from the list and sets @search_domain accordingly.  The
  # remaining terms are returned as a list.
  def _parse_params
    search_string = params[:search]
    logger.debug "1 #{search_string}"
    search_terms = search_string.split
    logger.debug "2 #{search_terms}"

    if params[:search_type] == "simple"

      # Look for and remove search-type keywords.
      searchtype_keywords = search_terms.select { |term| term =~ /^(trait|yield)s?/i }

      logger.debug "3 #{search_terms}"
      search_terms -= searchtype_keywords
      logger.debug "4 #{search_terms}"

      # For now, assume user doesn't use a keyword more than once.
      if searchtype_keywords.size != 1
        @search_domain = "('traits', 'yields')"
        return search_terms
      end

      if searchtype_keywords.first  =~ /yields?/i
        @search_domain = "('yields')"
      else
        @search_domain = "('traits')"
      end
      
    elsif params[:search_type] == "advanced"

      if params[:show_yields] and params[:show_traits]
        
        @search_domain = "('traits', 'yields')"

      elsif params[:show_yields]

        @search_domain = "('yields')"

      elsif params[:show_traits]

        @search_domain = "('traits')"

      else

        raise "You must select a search domain"

      end

    end

    params[:search] = search_terms.join ' '

    return search_terms
  end
      
end
