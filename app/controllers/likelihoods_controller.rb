class LikelihoodsController < ApplicationController

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
     search_cond = [Likelihood.column_names.collect {|x| "likelihoods." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search_cond[0] += " or " + Variable.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Run.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Model.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Input.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Site.search_columns.join(" like :search or ") + " like :search"
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @likelihoods = Likelihood.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :include => [:variable,{:run => :model},{:input => :site}], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "likelihoods.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end

  # GET /likelihoods
  # GET /likelihoods.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @likelihoods = Likelihood.paginate :page => params[:page], :per_page => 20
    else
      conditions = {}
      params.each do |k,v|
        next if !Likelihood.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @likelihoods = Likelihood.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @likelihoods }
      format.csv  { render :csv => @likelihoods }
      format.json  { render :json => @likelihoods }
    end
  end

  # GET /likelihoods/1
  # GET /likelihoods/1.xml
  def show
    @likelihood = Likelihood.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @likelihood }
      format.csv  { render :csv => @likelihood }
      format.json  { render :json => @likelihood }
    end
  end

  # GET /likelihoods/new
  # GET /likelihoods/new.xml
  def new
    @likelihood = Likelihood.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @likelihood }
      format.csv  { render :csv => @likelihood }
      format.json  { render :json => @likelihood }
    end
  end

  # GET /likelihoods/1/edit
  def edit
    @likelihood = Likelihood.find(params[:id])
  end

  # POST /likelihoods
  # POST /likelihoods.xml
  def create
    @likelihood = Likelihood.new(params[:likelihood])

    respond_to do |format|
      if @likelihood.save
        format.html { redirect_to(@likelihood, :notice => 'Likelihood was successfully created.') }
        format.xml  { render :xml => @likelihood, :status => :created, :location => @likelihood }
        format.csv  { render :csv => @likelihood, :status => :created, :location => @likelihood }
        format.json  { render :json => @likelihood, :status => :created, :location => @likelihood }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @likelihood.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @likelihood.errors, :status => :unprocessable_entity }
        format.json  { render :json => @likelihood.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /likelihoods/1
  # PUT /likelihoods/1.xml
  def update
    @likelihood = Likelihood.find(params[:id])

    respond_to do |format|
      if @likelihood.update_attributes(params[:likelihood])
        format.html { redirect_to(@likelihood, :notice => 'Likelihood was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @likelihood.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @likelihood.errors, :status => :unprocessable_entity }
        format.json  { render :json => @likelihood.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /likelihoods/1
  # DELETE /likelihoods/1.xml
  def destroy
    @likelihood = Likelihood.find(params[:id])
    @likelihood.destroy

    respond_to do |format|
      format.html { redirect_to(likelihoods_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end
end
