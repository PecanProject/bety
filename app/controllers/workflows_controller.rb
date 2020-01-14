class WorkflowsController < ApplicationController
  before_action :login_required, :except => [ :show ]
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
