class EnsemblesController < ApplicationController


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
        @current_sort = sort
        @current_sort_order = false
      end
    end

    if !@search.blank?
      if wildcards 
       @search = "%#{@search}%"
     end
     search_cond = [Ensemble.column_names.collect {|x| "ensembles." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @ensembles = Ensemble.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "ensembles.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end


  # GET /ensembles
  # GET /ensembles.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @ensembles = Ensemble.paginate :page => params[:page], :per_page => 20
    else
      conditions = {}
      params.each do |k,v|
        next if !Ensemble.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @ensembles = Ensemble.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
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
