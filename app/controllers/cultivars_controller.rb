class CultivarsController < ApplicationController
  before_filter :login_required, :except => [ :show ]


  layout 'application'

  require 'csv'

 def search
    sort = params[:sort]

    @page = params[:page]
    @current_sort = params[:current_sort]
    params[:current_sort_order].match(/true/) ? @current_sort_order = true : @current_sort_order = false

    @search = params[:search]
    # If they search just a number it is probably an id, and we do not want to wrap that in wildcards.
    @search.match(/\D/) ? wildcards = true : wildcards = false

    #Different from rest to deal with "species/specie"...
    if sort and ((sort.match(/species/) and Specie.column_names.include?(sort.split(".")[1])) or sort.split(".")[0].classify.constantize.column_names.include?(sort.split(".")[1]))
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
     search_cond = [Cultivar.column_names.collect {|x| "cultivars." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search_cond[0] += " or " + Specie.search_columns.join(" like :search or ") + " like :search"
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @cultivars = Cultivar.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :include => [:specie], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "cultivars.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end

  # GET /cultivars
  # GET /cultivars.xml
  def index
    #@cultivars = Cultivar.all
    if params[:format].nil? or params[:format] == 'html'
      @cultivars = Cultivar.paginate :page => params[:page], :per_page => 20
    else
      conditions = {}
      params.each do |k,v|
        next if !Cultivar.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @cultivars = Cultivar.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
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
