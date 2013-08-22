# This controller handles searches.
include AuthenticatedSystem

class SearchController < ApplicationController
  helper_method :sort_column, :sort_direction

  HEADER = <<CREDITS
David LeBauer, Dan Wang, and Michael Dietze, 2010.  \
Biofuel Ecophysiological Traits and Yields Database Version 1.0.  \
Energy Biosciences Institute, Urbana, IL
CREDITS
  HEADER.chomp!

  CONTACT_EMAIL = "dlebauer@illinois.edu"

  FORMAT_STRING = <<FORMAT
%<credits>s

Contact:,%<contact_email>s

SQL query:,%<query>s

Date of query:,%<date>s

%<data>s
FORMAT


  def index
    #if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @results = TraitsAndYieldsView
        .sorted_order("#{sort_column('traits_and_yields_view','scientificname')} #{sort_direction}")
        .search(params[:search])
        .paginate :page => params[:page], :per_page => params[:DataTables_Table_0_length]
    #else # Allow url queries of data, with scopes, only xml & csv ( & json? )
     # @results = TraitsAndYieldsView.api_search(params)
    #end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @results }
      format.csv do 
        sql_query = TraitsAndYieldsView.search(params[:search]).to_sql
        # escape any fields that may contain interal commas or double quotes:
        str = sprintf(FORMAT_STRING, credits: escape_for_excel(HEADER), contact_email: CONTACT_EMAIL, query: escape_for_excel(sql_query), date: Time.now, data: @results.to_comma)
        send_data str, type: Mime::CSV,
        disposition: "attachment; filename=search_results.csv"
      end
      format.json  { render :json => @results }
    end
  end

  private
  def escape_for_excel(str)
    str.gsub '"', '""'
    return "\"#{str}\""
  end
      
end
