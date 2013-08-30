# This controller handles searches.
include AuthenticatedSystem

class SearchController < ApplicationController
  helper_method :sort_column, :sort_direction

  CREDITS = <<CREDITS
David LeBauer, Dan Wang, and Michael Dietze, 2010.  \
Biofuel Ecophysiological Traits and Yields Database Version 1.0.  \
Energy Biosciences Institute, Urbana, IL
CREDITS
  CREDITS.chomp!

  CONTACT_EMAIL = "dlebauer@illinois.edu"


  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @results = TraitsAndYieldsView
        .sorted_order("#{sort_column('traits_and_yields_view','scientificname')} #{sort_direction}")
        .search(params[:search])
        .paginate :page => params[:page], :per_page => params[:DataTables_Table_0_length]
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @results = TraitsAndYieldsView
        .restrict_access(current_user ? current_user.access_level : 4)
        .search(params[:search])
    end

    log_searches(TraitsAndYieldsView)

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @results }
      format.csv do 
        sql_query = TraitsAndYieldsView
          .search(params[:search])
          .restrict_access(current_user ? current_user.access_level : 4)
          .to_sql
        header = CSV.generate do |csv|
          csv << [ "# " + CREDITS ]
          csv << [ "#" ]
          csv << [ "# Contact:", CONTACT_EMAIL ]
          csv << [ "#" ]
          csv << [ "# SQL query:", sql_query ]
          csv << [ "#" ]
          csv << [ "# Date of query:", Time.now ]
          csv << [ "#" ]
        end

        str = header + @results.to_comma
        send_data str, type: Mime::CSV,
        disposition: "attachment; filename=search_results.csv"
      end
      format.json  { render :json => @results }
    end
  end

end
