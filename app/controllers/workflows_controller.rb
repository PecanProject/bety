class WorkflowsController < ApplicationController
  before_filter :login_required, :except => [ :show ]
  helper_method :sort_column, :sort_direction

  require 'csv'

  # GET /workflows
  # GET /workflows.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      # We will list those already linked above those that are not, so remove them from the list.
      @workflows = Workflow.sorted_order("#{sort_column('workflows','outdir')} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else
      @workflows = Workflow.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @workflows }
      format.csv  { render :csv => @workflows }
      format.json { render :json => @workflows }
    end
  end

  # GET /workflows/1
  # GET /workflows/1.xml
  def show
    @workflow = Workflow.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @workflow }
      format.csv  { render :csv => @workflow }
      format.json  { render :json => @workflow }
    end
  end

  # GET /workflows/new
  # GET /workflows/new.xml
  def new
    @workflow = Workflow.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @workflow }
      format.csv  { render :csv => @workflow }
      format.json  { render :json => @workflow }
    end
  end

  # GET /workflows/1/edit
  def edit
    @workflow = Workflow.find(params[:id])
  end

  # POST /workflows
  # POST /workflows.xml
  def create
    @workflow = Workflow.new(params[:workflow])


    respond_to do |format|
      if @workflow.save
        format.html { redirect_to(@workflow, :notice => 'Workflow was successfully created.') }
        format.xml  { render :xml => @workflow, :status => :created, :location => @workflow }
        format.csv  { render :csv => @workflow, :status => :created, :location => @workflow }
        format.json  { render :json => @workflow, :status => :created, :location => @workflow }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @workflow.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @workflow.errors, :status => :unprocessable_entity }
        format.json  { render :json => @workflow.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /workflows/1
  # PUT /workflows/1.xml
  def update
    @workflow = Workflow.find(params[:id])

    respond_to do |format|
      if @workflow.update_attributes(params[:workflow])
        format.html { redirect_to(@workflow, :notice => 'Workflow was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @workflow.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @workflow.errors, :status => :unprocessable_entity }
        format.json  { render :json => @workflow.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /workflows/1
  # DELETE /workflows/1.xml
  def destroy
    @workflow = Workflow.find(params[:id])
    @workflow.destroy

    respond_to do |format|
      format.html { redirect_to(workflows_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end
end
