# This controller handles searches.
include AuthenticatedSystem
class SearchesController < ApplicationController

  # This should be used on opening the home page ... before a user logs in
  # On attempting to login from this page ... feed it to the create method in this controller
  def index
#    @user.new = User.new
#    @session.new = Session.new

    search_string = params[:search]

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
    search_condition = clause_array.join(' AND ')
  

    # We use each term three times, so duplicate them.
    search_terms.map! do |term|
      [term, term, term]
    end
    search_terms.flatten!
    
    @results = []
    if ["traits", "both"].find_index @search_type
      @results = Traitsview.find(:all, 
                                :conditions => [
                                                search_condition,
                                                search_terms
                                               ].flatten!)
    end
    
    if ["yields", "both"].find_index @search_type
      @results += Yieldsview.find(:all, 
                                 :conditions => [
                                                 search_condition,
                                                 search_terms
                                                ].flatten!)
    end

    respond_to do |format|
      format.html # index.html.erb
    end


    end

  end

  # probably should be in a helper, but put here for now:
  #
  # Expects a list of search terms.  If the terms "yield" or "trait"
  # occur (in any case and in either singular or plural form) it
  # removes them from the list and sets @search_type accordingly.  The
  # remaining terms are returned as a list.
  def _parse_params
    search_string = params[:search]
    logger.debug "1 #{search_string}"
    search_terms = search_string.split
    logger.debug "2 #{search_terms}"

    # Look for and remove search-type keywords.
    searchtype_keywords = search_terms.select { |term| term =~ /^(trait|yield)s?/i }

    logger.debug "3 #{search_terms}"
    search_terms -= searchtype_keywords
    logger.debug "4 #{search_terms}"

    # For now, assume user doesn't use a keyword more than once.
    if searchtype_keywords.size != 1
      @search_type = "both"
      return search_terms
    end

    if searchtype_keywords.first  =~ /yields?/i
      @search_type = "yields"
    else
      @search_type = "traits"
    end

    return search_terms
  end
      
end
