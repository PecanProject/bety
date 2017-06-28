class ExperimentsController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

  # GET /experiments
  # GET /experiments.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @experiments = Experiment.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else
      @experiments = Experiment.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @experiments }
      format.csv  { render :csv => @experiments }
      format.json  { render :json => @experiments }
    end
  end


  # GET /experiments/1
  # GET /experiments/1.xml
  def show
    @experiment = Experiment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @experiment }
    end
  end

  # GET /experiments/new
  # GET /experiments/new.xml
  def new
    @experiment = Experiment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @experiment }
      format.csv  { render :csv => @experiment }
      format.json  { render :json => @experiment }
    end
  end

  # POST /experiments
  # POST /experiments.xml
  def create

    @experiment = Experiment.new(params[:experiment])
    @experiment.user_id = current_user.id

    respond_to do |format|
      if @experiment.save
        format.html { redirect_to(@experiment, :notice => 'Experiment was successfully created.') }
        format.xml  { render :xml => @experiment, :status => :created, :location => @experiment }
        format.csv  { render :csv => @experiment, :status => :created, :location => @experiment }
        format.json  { render :json => @experiment, :status => :created, :location => @experiment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @experiment.errors, :status => :unprocessable_entity }
        format.json  { render :json => @experiment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # GET /experiments/1/edit
  def edit
    @experiment = Experiment.find(params[:id])
  end

  # PUT /experiments/1
  # PUT /experiments/1.xml
  def update
    @experiment = Experiment.find(params[:id])

    respond_to do |format|
      if @experiment.update_attributes(params[:experiment])
        format.html { redirect_to(@experiment, :notice => 'Experiment was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @experiment.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @experiment.errors, :status => :unprocessable_entity }
        format.json  { render :json => @experiment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /experiments/1
  # DELETE /experiments/1.xml
  def destroy
    @experiment = Experiment.find(params[:id])
    @experiment.destroy

    respond_to do |format|
      format.html { redirect_to(experiments_url) }
      format.xml  { head :ok }
    end
  end

end
