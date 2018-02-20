class ManagementsController < ApplicationController
  before_action :login_required
  helper_method :sort_column, :sort_direction

  require 'csv'

  def search_treatments
    @management = Management.find(params[:id])

    # the "sorted_order" call is mainly so "search" has the joins it needs
    @treatments = Treatment.sorted_order("#{sort_column('treatments','updated_at')} #{sort_direction}").search(params[:search_treatments])

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  def rem_managements_treatments
    @management = Management.find(params[:id])
    @treatment = Treatment.find(params[:treatment])

    @management.treatments.delete(@treatment)

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  def add_managements_treatments

    @management = Management.find(params[:id])
    @treatment = Treatment.find(params[:treatment])

    @management.treatments << @treatment

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  # GET /managements
  # GET /managements.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @managements = Management.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page],
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(Management)
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @managements = Management.api_search(params)
      log_searches(Management.method(:api_search), params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @managements }
      format.csv  { render :csv => @managements }
      format.json  { render :json => @managements }
    end
  end

  # GET /managements/1
  # GET /managements/1.xml
  def show
    @management = Management.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @management }
      format.csv  { render :csv => @management }
      format.json  { render :json => @management }
    end
  end

  # GET /managements/new
  # GET /managements/new.xml
  def new

    @management = Management.new

    respond_to do |format|
      if !params[:treatment].nil?
        @treatment = params[:treatment]
        format.html # new.html.erb
        format.xml  { render :xml => @management }
        format.csv  { render :csv => @management }
        format.json  { render :json => @management }
      elsif session['citation'].nil?
        format.html {
          flash[:notice] = "Please choose a citation to work with first."
          redirect_to managements_path
        }
      else
        if Citation.find(session["citation"]).treatments.size == 0
          flash[:notice] = 'You must associate a treatment with this citation before adding a new management'
        end
        format.html { redirect_to treatments_path }
      end
    end
  end

  # GET /managements/1/edit
  def edit
    @management = Management.find(params[:id])
    @treatments = @management.treatments

    respond_to do |format|
      format.html
      format.js {
        render layout: false
      }
    end
 end

  # POST /managements
  # POST /managements.xml
  def create
    @management = Management.new(params[:management])
    @management.citation = Citation.find(session["citation"]) if !session["citation"].nil?
    
    # they should only add management when they have a citation selected
    # and they came via the 'new' link on the treatments page which
    # will provide a treatment_id, if not we should not create it
        
    problem = true if params[:treatment].empty? or session["citation"].nil?

    @management.user = current_user

    respond_to do |format|
      if (( !problem ) or !params[:format].nil?) and @management.save
        @management.treatments << Treatment.find(params[:treatment])
        flash[:notice] = 'Management was successfully created.'
        format.html { redirect_to( treatments_path ) }
        format.xml  { render :xml => @management, :status => :created, :location => @management }
        format.csv  { render :csv => @management, :status => :created, :location => @management }
        format.json  { render :json => @management, :status => :created, :location => @management }
      else
        flash[:notice] = 'Management was not created.'
        format.html { redirect_to( treatments_path ) }
        format.xml  { render :xml => @management.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @management.errors, :status => :unprocessable_entity }
        format.json  { render :json => @management.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /managements/1
  # PUT /managements/1.xml
  def update
    @management = Management.find(params[:id])

    params[:management].delete("user_id")

    respond_to do |format|
      if @management.update_attributes(params[:management])
        flash[:notice] = 'Management was successfully updated.'
        format.html { redirect_to( :action => :edit ) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { @treatments = @management.treatments
                      render :action => "edit" }
        format.xml  { render :xml => @management.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @management.errors, :status => :unprocessable_entity }
        format.json  { render :json => @management.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /managements/1
  # DELETE /managements/1.xml
  def destroy
    @management = Management.find(params[:id])
    @management.destroy

    respond_to do |format|
      format.html { redirect_to(managements_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
