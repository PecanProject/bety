# This controller handles searches.
include AuthenticatedSystem

class SearchController < ApplicationController
  before_filter :login_required, :except => [ :show ]
  helper_method :sort_column, :sort_direction

  require 'csv'

  # GET /species
  # GET /species.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @results = TraitsAndYieldsView
        .sorted_order("#{sort_column('traits_and_yields_view','scientificname')} #{sort_direction}")
        .search(params[:search])
        .paginate :page => params[:page], :per_page => params[:DataTables_Table_0_length]
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @results = TraitsAndYieldsView.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @results }
      format.csv  { render :csv => @results }
      format.json  { render :json => @results }
    end
  end
      
end
