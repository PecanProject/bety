class CovariatesController < ApplicationController
  before_filter :login_required

  layout 'application'
  def search
    sort = params[:sort]

    @page = params[:page]
    @current_sort = params[:current_sort]
    params[:current_sort_order].match(/true/) ? @current_sort_order = true : @current_sort_order = false

    @search = params[:search]
    # If they search just a number it is probably an id, and we do not want to wrap that in wildcards.
    @search.match(/\D/) ? wildcards = true : wildcards = false

    if sort and sort.split(".")[0].classify.constantize.column_names.include?(sort.split(".")[1])
      if @current_sort == sort
        @current_sort_order = !@current_sort_order
      else
        logger.info "here"
        @current_sort = sort
        @current_sort_order = false
      end
    end

    if !@search.blank?
      if wildcards 
       @search = "%#{@search}%"
     end
     search_cond = [Covariate.column_names.collect {|x| "covariates." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search_cond[0] += " or " + Trait.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Variable.search_columns.join(" like :search or ") + " like :search"
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @covariates = Covariate.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :include => [:trait, :variable], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "covariates.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end


  # GET /covariates
  # GET /covariates.xml
  def index
    #@covariates = Covariate.all
    if params[:format].nil? or params[:format] == 'html'
      @covariates = Covariate.paginate :page => params[:page]
    else
      conditions = {}
      params.each do |k,v|
        next if !Covariate.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @covariates = Covariate.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
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
