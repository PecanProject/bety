class YieldsController < ApplicationController
  before_action :login_required, :except => [ :show ]
  helper_method :sort_column, :sort_direction

  require 'csv'

  def checked
    id = params[:id]
    y = Yield.all_limited(current_user).find(id)

    if y
      y.checked = params[:y][:checked]
    end

    @element_id = "checked_notify-#{id}"
    binding.pry
    if y && y.save
      @message = "<br />Updated to #{y.checked}"
    else
      @message = "<br />Something went wrong, not updated!"
    end

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  def access_level

    y = Yield.all_limited(current_user).find(params[:id])
    y.access_level = params[:yield][:access_level] if y
    

    @element_id = "access_level-#{y.id}"

    if y && y.save
      @saved = true
    else
      @saved = false
    end

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  # GET /yields
  # GET /yields.xml
  def index
    @yields = Yield.all_limited(current_user)
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @yields = @yields.citation(session["citation"]).sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(@yields.citation(session["citation"]).search(params[:search]).to_sql)
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @yields = @yields.api_search(params)
      log_searches(@yields.api_search(params).to_sql)
    end

    respond_to do |format|
      format.html 
      format.js 
      format.xml  { render :xml => @yields }
      format.json { render :json => @yields }
      format.csv  { render :csv => @yields, :style => (params[:style] ||= 'default').to_sym }
    end
  end

  # GET /yields/1
  # GET /yields/1.xml
  def show
    @yield = Yield.all_limited(current_user).find(params[:id])

    if !logged_in?
      @yield = nil if !@yield.checked or @yield.access_level < 4
    elsif @yield.user_id == current_user.id or current_user.access_level == 1 or current_user.page_access_level <= 2
      #Every one can see what they created, makes the else easier. People in Dietz lab can see everything and 'Datta Managers' can see everything
    else
      @yield = nil if !@yield.checked or current_user.access_level > @yield.access_level
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @yield }
      format.csv  { render :csv => @yield }
    end
  end

  # GET /yields/new
  # GET /yields/new.xml
  def new
    if session["citation"].nil?
      flash[:notice] = 'Choose a citation to work with ( Actions Tab > Check )'
      redirect_to :citations
    else
      @citation = Citation.find(session["citation"])
      @sites = @citation.sites
      @treatments = @citation.treatments
      
      if params[:id].nil?
        @yield = Yield.new
      else
        @yield = Yield.all_limited(current_user).find(params[:id]).dup
        @yield.specie.nil? ? @species = nil : @species = [@yield.specie]
      end

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @yield }
        format.csv  { render :csv => @yield }
      end
    end
  end

  # GET /yields/1/edit
  def edit
    @yield = Yield.all_limited(current_user).find(params[:id])
    @yield.specie.nil? ? @species = nil : @species = [@yield.specie]
    @citation = @yield.citation
    @sites = @citation.sites
    @treatments = @citation.treatments
  end

  # POST /yields
  # POST /yields.xml
  def create

    @yield = Yield.new(params[:yield])

    @yield.user_id = current_user.id

    logger.info "Current user: #{current_user.id}"

    respond_to do |format|
      if @yield.save
        flash[:notice] = 'Yield was successfully created.'
        format.html { redirect_to :action => "new", :id => @yield }
        format.xml  { render :xml => @yield, :status => :created, :location => @yield }
        format.csv  { render :csv => @yield, :status => :created, :location => @yield }
      else
        @treatments = Citation.find_by_id(session["citation"]).treatments rescue nil
        @sites = Citation.find_by_id(session["citation"]).sites rescue nil
        format.html { render :action => "new" }
        format.xml  { render :xml => @yield.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @yield.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /yields/1
  # PUT /yields/1.xml
  def update
    @yield = Yield.all_limited(current_user).find(params[:id])

    @yield.assign_attributes(params[:yield])

    if params['assign_creator']
      @yield.user_id = current_user.id
    end

    respond_to do |format|
      # This save is a no-op unless Julian date was set:
      if @yield.save
        flash[:notice] = 'Yield was successfully updated.'
        format.html { redirect_to(@yield) }
        format.xml  { head :ok }
        format.csv  { head :ok }
      else
        citation = @yield.citation
        @treatments = citation.treatments
        @sites = citation.sites
        format.html { render :action => "edit" }
        format.xml  { render :xml => @yield.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @yield.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /yields/1
  # DELETE /yields/1.xml
  def destroy
    @yield = Yield.all_limited(current_user).find(params[:id])
    @yield.destroy

    respond_to do |format|
      format.html { redirect_to(yields_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
    end
  end

end
