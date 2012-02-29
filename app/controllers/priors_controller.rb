class PriorsController < ApplicationController
  before_filter :login_required

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
     search_cond = [Prior.column_names.collect {|x| "priors." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search_cond[0] += " or " + Citation.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Variable.search_columns.join(" like :search or ") + " like :search"
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @priors = Prior.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :include => [:citation, :variable], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "priors.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end

  def rem_pfts_priors
    @pft = Pft.find(params[:id])
    @prior = Prior.find(params[:prior])

    render :update do |page|
      @pft.priors.delete(@prior)
      page.replace_html 'edit_pfts_priors', :partial => 'edit_pfts_priors'
    end
  end

  def edit_pfts_priors

    @prior = Prior.find(params[:id])

    render :update do |page|
      if !params[:pft].nil?
        params[:pft][:id].each do |c|
          @prior.pfts << Pft.find(c)
        end
      end
      page.replace_html 'edit_pfts_priors', :partial => 'edit_pfts_priors'
    end
  end

  # GET /priors
  # GET /priors.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @priors = Prior.paginate :page => params[:page], :per_page => 20, :order => "updated_at desc"
    else
      conditions = {}
      params.each do |k,v|
        next if !Prior.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @priors = Prior.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @priors }
      format.csv  { render :csv => @priors }
      format.json  { render :json => @priors }
    end
  end

  # GET /priors/1
  # GET /priors/1.xml
  def show
    @prior = Prior.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @prior }
      format.csv  { render :csv => @prior }
      format.json  { render :json => @prior }
    end
  end

  # GET /priors/new
  # GET /priors/new.xml
  def new
    @prior = Prior.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @prior }
      format.csv  { render :csv => @prior }
      format.json  { render :json => @prior }
    end
  end

  # GET /priors/1/edit
  def edit
    @prior = Prior.find(params[:id])
  end

  # POST /priors
  # POST /priors.xml
  def create
    @prior = Prior.new(params[:prior])

    respond_to do |format|
      if @prior.save
        flash[:notice] = 'Prior was successfully created.'
        format.html { redirect_to( edit_prior_path(@prior) ) }
        format.xml  { render :xml => @prior, :status => :created, :location => @prior }
        format.csv  { render :csv => @prior, :status => :created, :location => @prior }
        format.json  { render :json => @prior, :status => :created, :location => @prior }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @prior.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @prior.errors, :status => :unprocessable_entity }
        format.json  { render :json => @prior.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /priors/1
  # PUT /priors/1.xml
  def update
    @prior = Prior.find(params[:id])

    respond_to do |format|
      if @prior.update_attributes(params[:prior])
        flash[:notice] = 'Prior was successfully updated.'
        format.html { redirect_to( edit_prior_path(@prior)) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @prior.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @prior.errors, :status => :unprocessable_entity }
        format.json  { render :json => @prior.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /priors/1
  # DELETE /priors/1.xml
  def destroy
    @prior = Prior.find(params[:id])
    @prior.pfts.destroy
    @prior.destroy

    respond_to do |format|
      format.html { redirect_to(priors_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end
end
