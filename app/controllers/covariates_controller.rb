class CovariatesController < ApplicationController
  before_filter :login_required
  helper_method :sort_column, :sort_direction

  # GET /covariates
  # GET /covariates.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @covariates = Covariate.sorted_order("#{sort_column('covariates')} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(Covariate)
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @covariates = Covariate.api_search(params)
      log_searches(Covariate.method(:api_search), params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js 
      format.xml  { render :xml => @covariates }
      format.csv  { render :csv => @covariates }
      format.json  { render :json => @covariates }
    end
  end

  # GET /covariates/1
  # GET /covariates/1.xml
  def show
    @covariate = Covariate.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @covariate }
      format.csv  { render :csv => @covariate }
      format.json  { render :json => @covariate }
    end
  end

  # GET /covariates/new
  # GET /covariates/new.xml
  def new
    @covariate = Covariate.new

    if !params[:trait_id].nil?
      @covariate.trait = Trait.find(params[:trait_id]) 
      @trait = [@covariate.trait]
    else
      @trait = nil
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @covariate }
      format.csv  { render :csv => @covariate }
      format.json  { render :json => @covariate }
    end
  end

  # GET /covariates/1/edit
  def edit
    @covariate = Covariate.find(params[:id])
    @covariate.trait.nil? ? @trait = nil : @trait = [@covariate.trait]
  end

  # POST /covariates
  # POST /covariates.xml
  def create
    @covariate = Covariate.new(params[:covariate])

    respond_to do |format|
      if @covariate.save
        flash[:notice] = 'Covariate was successfully created.'
        if params[:commit] == "Create"
          format.html { redirect_to(@covariate) }
        else
          format.html { redirect_to :action => "new", :trait_id => @covariate.trait_id }
        end
        format.xml  { render :xml => @covariate, :status => :created, :location => @covariate }
        format.csv  { render :csv => @covariate, :status => :created, :location => @covariate }
        format.json  { render :json => @covariate, :status => :created, :location => @covariate }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @covariate.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @covariate.errors, :status => :unprocessable_entity }
        format.json  { render :json => @covariate.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /covariates/1
  # PUT /covariates/1.xml
  def update
    @covariate = Covariate.find(params[:id])

    respond_to do |format|
      if @covariate.update_attributes(params[:covariate])
        flash[:notice] = 'Covariate was successfully updated.'
        format.html { redirect_to(@covariate) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @covariate.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @covariate.errors, :status => :unprocessable_entity }
        format.json  { render :json => @covariate.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /covariates/1
  # DELETE /covariates/1.xml
  def destroy
    @covariate = Covariate.find(params[:id])
    @covariate.destroy

    respond_to do |format|
      format.html { redirect_to(covariates_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
