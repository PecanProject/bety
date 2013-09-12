class EnsemblesController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

  # GET /ensembles
  # GET /ensembles.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @ensembles = Ensemble.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else
      @ensembles = Ensemble.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @ensembles }
      format.csv  { render :csv => @ensembles }
      format.json  { render :json => @ensembles }
    end
  end


  # GET /ensembles/1
  # GET /ensembles/1.xml
  def show
    @ensemble = Ensemble.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @ensemble }
    end
  end

  # GET /ensembles/new
  # GET /ensembles/new.xml
  def new
    @ensemble = Ensemble.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @ensemble }
    end
  end

  # GET /ensembles/1/edit
  def edit
    @ensemble = Ensemble.find(params[:id])
  end

  # POST /ensembles
  # POST /ensembles.xml
  def create
    @ensemble = Ensemble.new(params[:ensemble])

    respond_to do |format|
      if @ensemble.save
        format.html { redirect_to(@ensemble, :notice => 'Ensemble was successfully created.') }
        format.xml  { render :xml => @ensemble, :status => :created, :location => @ensemble }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @ensemble.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ensembles/1
  # PUT /ensembles/1.xml
  def update
    @ensemble = Ensemble.find(params[:id])

    respond_to do |format|
      if @ensemble.update_attributes(params[:ensemble])
        format.html { redirect_to(@ensemble, :notice => 'Ensemble was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @ensemble.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ensembles/1
  # DELETE /ensembles/1.xml
  def destroy
    @ensemble = Ensemble.find(params[:id])
    @ensemble.destroy

    respond_to do |format|
      format.html { redirect_to(ensembles_url) }
      format.xml  { head :ok }
    end
  end

end
