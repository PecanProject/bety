class PosteriorsController < ApplicationController

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
     search_cond = [Posterior.column_names.collect {|x| "posteriors." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search_cond[0] += " or " + Pft.search_columns.join(" like :search or ") + " like :search"
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @posteriors = Posterior.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :include => [:pft], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "posteriors.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end


  def rem_posteriors_runs
    @posterior = Posterior.find(params[:posterior_id])
    @run = Run.find(params[:run_id])

    render :update do |page|
      @posterior.runs.delete(@run)
      page.replace_html 'edit_posteriors_runs', :partial => 'edit_posteriors_runs'
    end
  end

  def edit_posteriors_runs

    @posterior = Posterior.find(params[:posterior_id])

    render :update do |page|
      if !params[:run].nil?
        params[:run][:id].each do |run|
          @posterior.runs << Run.find(run)
        end
      end
      page.replace_html 'edit_posteriors_runs', :partial => 'edit_posteriors_runs'
    end
  end

  # GET /posteriors
  # GET /posteriors.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @posteriors = Posterior.paginate :page => params[:page], :per_page => 20
    else
      conditions = {}
      params.each do |k,v|
        next if !Posterior.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @posteriors = Posterior.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @posteriors }
      format.csv  { render :csv => @posteriors }
      format.json  { render :json => @posteriors }
    end
  end

  # GET /posteriors/1
  # GET /posteriors/1.xml
  def show
    @posterior = Posterior.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @posterior }
      format.csv  { render :csv => @posterior }
      format.json  { render :json => @posterior }
    end
  end

  # GET /posteriors/new
  # GET /posteriors/new.xml
  def new
    @posterior = Posterior.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @posterior }
      format.csv  { render :csv => @posterior }
      format.json  { render :json => @posterior }
    end
  end

  # GET /posteriors/1/edit
  def edit
    @posterior = Posterior.find(params[:id])
  end

  # POST /posteriors
  # POST /posteriors.xml
  def create
    @posterior = Posterior.new(params[:posterior])

    respond_to do |format|
      if @posterior.save
        format.html { redirect_to(@posterior, :notice => 'Posterior was successfully created.') }
        format.xml  { render :xml => @posterior, :status => :created, :location => @posterior }
        format.csv  { render :csv => @posterior, :status => :created, :location => @posterior }
        format.json  { render :json => @posterior, :status => :created, :location => @posterior }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @posterior.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @posterior.errors, :status => :unprocessable_entity }
        format.json  { render :json => @posterior.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /posteriors/1
  # PUT /posteriors/1.xml
  def update
    @posterior = Posterior.find(params[:id])

    respond_to do |format|
      if @posterior.update_attributes(params[:posterior])
        format.html { redirect_to(@posterior, :notice => 'Posterior was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @posterior.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @posterior.errors, :status => :unprocessable_entity }
        format.json  { render :json => @posterior.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /posteriors/1
  # DELETE /posteriors/1.xml
  def destroy
    @posterior = Posterior.find(params[:id])
    @posterior.destroy

    respond_to do |format|
      format.html { redirect_to(posteriors_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end
end
