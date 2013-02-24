class YieldsviewsController < ApplicationController
  before_filter :login_required

  require 'csv'

  # GET /yields/1
  # GET /yields/1.xml
  def show
    @yield = Yieldsview.all_limited(current_user).find_by_yield_id(params[:id])

    if !logged_in? or @yield.nil?
      @yield = nil if @yield.nil? or !@yield.checked or @yield.access_level < 4
    elsif @yield.user_id == current_user.id or current_user.access_level == 1 or current_user.page_access_level <= 2
      #Every one can see what they created, makes the else easier. People in Dietz lab can see everything and 'Datta Managers' can see everything
    else
      @yield = nil if !@yield.checked or current_user.access_level > @yield.access_level
    end

    respond_to do |format|
      if @yield.nil?
        format.html { render :nothing => true, :status => 404 }
      else
        format.xml  { render :xml => @yield }
        format.json { render :json => @yield }
        format.csv  { render :csv => @yield }
      end
    end
  end

end

