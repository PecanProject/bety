class VariablesController < ApplicationController
  before_filter :login_required
  helper_method :sort_column, :sort_direction

  require 'csv'

  # GET /variables
  # GET /variables.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @variables = Variable.sorted_order("#{sort_column('variables','name')} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(Variable)
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @variables = Variable.api_search(params)
      log_searches(Variable.method(:api_search), params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @variables }
      format.csv  { render :csv => @variables }
      format.json  { render :json => @variables }
    end
  end

  # GET /variables/1
  # GET /variables/1.xml
  def show
    @variable = Variable.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @variable }
      format.csv  { render :csv => @variable }
      format.json  { render :json => @variable }
    end
  end

  # GET /variables/new
  # GET /variables/new.xml
  def new
    @variable = Variable.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @variable }
      format.csv  { render :csv => @variable }
      format.json  { render :json => @variable }
    end
  end

  # GET /variables/1/edit
  def edit
    @variable = Variable.find(params[:id])
  end

  # POST /variables
  # POST /variables.xml
  def create
    @variable = Variable.new(params[:variable])

    respond_to do |format|
      if @variable.save
        flash[:notice] = 'Variable was successfully created.'
        format.html { redirect_to( edit_variable_path(@variable) ) }
        format.xml  { render :xml => @variable, :status => :created, :location => @variable }
        format.csv  { render :csv => @variable, :status => :created, :location => @variable }
        format.json  { render :json => @variable, :status => :created, :location => @variable }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @variable.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @variable.errors, :status => :unprocessable_entity }
        format.json  { render :json => @variable.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /variables/1
  # PUT /variables/1.xml
  def update
    @variable = Variable.find(params[:id])

    respond_to do |format|
      if @variable.update_attributes(params[:variable])
        flash[:notice] = 'Variable was successfully updated.'
        format.html { redirect_to(@variable) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @variable.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @variable.errors, :status => :unprocessable_entity }
        format.json  { render :json => @variable.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /variables/1
  # DELETE /variables/1.xml
  def destroy
    @variable = Variable.find(params[:id])
    @variable.traits.destroy
    @variable.destroy

    respond_to do |format|
      format.html { redirect_to(variables_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
