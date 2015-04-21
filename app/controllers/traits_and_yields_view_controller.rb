class TraitsAndYieldsViewController < ApplicationController
  before_filter :login_required

  require 'csv'

  def index
    @data = TraitsAndYieldsView.api_search(params)
    log_searches(TraitsAndYieldsView.method(:api_search), params)
    respond_to do |format|
        format.xml  { render :xml => @data }
        format.json { render :json => @data }
        format.csv  { render :csv => @data }
    end
  end
end