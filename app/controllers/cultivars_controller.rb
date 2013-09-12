class CultivarsController < ApplicationController
  before_filter :login_required, :except => [ :show ]
  helper_method :sort_column, :sort_direction

  require 'csv'

  # GET /cultivars
  # GET /cultivars.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @cultivars = Cultivar.sorted_order("#{sort_column('cultivars')} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page],
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(Cultivar)
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @cultivars = Cultivar.api_search(params)
      log_searches(Cultivar.method(:api_search), params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js # index.html.erb
      format.xml  { render :xml => @cultivars }
      format.csv  { render :csv => @cultivars }
      format.json  { render :json => @cultivars }
    end
  end

  # GET /cultivars/1
  # GET /cultivars/1.xml
  def show
    @cultivar = Cultivar.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cultivar }
      format.csv  { render :csv => @cultivar }
      format.json  { render :json => @cultivar }
    end
  end

  # GET /cultivars/new
  # GET /cultivars/new.xml
  def new
    @cultivar = Cultivar.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cultivar }
      format.csv  { render :csv => @cultivar }
      format.json  { render :json => @cultivar }
    end
  end

  # GET /cultivars/1/edit
  def edit
    @cultivar = Cultivar.find(params[:id])
    @species = [@cultivar.specie] if !@cultivar.specie.nil?
  end

  # POST /cultivars
  # POST /cultivars.xml
  def create
    @cultivar = Cultivar.new(params[:cultivar])

    respond_to do |format|
      if @cultivar.save
        flash[:notice] = 'Cultivar was successfully created.'
        format.html { redirect_to(@cultivar) }
        format.xml  { render :xml => @cultivar, :status => :created, :location => @cultivar }
        format.csv  { render :csv => @cultivar, :status => :created, :location => @cultivar }
        format.json  { render :json => @cultivar, :status => :created, :location => @cultivar }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cultivar.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @cultivar.errors, :status => :unprocessable_entity }
        format.json  { render :json => @cultivar.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cultivars/1
  # PUT /cultivars/1.xml
  def update
    @cultivar = Cultivar.find(params[:id])

    respond_to do |format|
      if @cultivar.update_attributes(params[:cultivar])
        flash[:notice] = 'Cultivar was successfully updated.'
        format.html { redirect_to( edit_cultivar_path(@cultivar) ) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cultivar.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @cultivar.errors, :status => :unprocessable_entity }
        format.json  { render :json => @cultivar.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cultivars/1
  # DELETE /cultivars/1.xml
  def destroy
    @cultivar = Cultivar.find(params[:id])
    @cultivar.destroy

    respond_to do |format|
      format.html { redirect_to(cultivars_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
