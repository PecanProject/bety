class SitesController < ApplicationController
  before_filter :login_required, :except => [ :show ]

  layout 'application', :except => [ :map ]

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
        logger.info "here"
        @current_sort = sort
        @current_sort_order = false
      end
    end

    if !@search.blank?
      if wildcards 
       @search = "%#{@search}%"
     end
     search_cond = [Site.column_names.collect {|x| "sites." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @sites = Site.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :conditions => search_cond 

    render :update do |page|
      page.replace_html :matches_count, "#{@sites.length} matches (see below)" if request.env['HTTP_REFERER'][/\/new$/]
      page << "if ( $('index_table') != null ) { $('index_table').show() }"
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "sites.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end

  #AJAX Calls
  def linked
    @citation = Citation.find(session["citation"])
    @site = Site.find(params[:id])

    exists = @citation.sites.exists?(@site.id)

    if exists
      @citation.sites.delete(@site)
    else
      @citation.sites<<@site
    end

    render :update do |page|
      page.replace_html "site-#{ @site.id }", ""
      page.replace_html "linked", :partial => 'linked'
    end
  end

  def rem_citations_sites
    @citation = Citation.find(params[:id])
    @site = Site.find(params[:site])

    render :update do |page|
      @citation.sites.delete(@site)
      page.replace_html 'edit_citations_sites', :partial => 'edit_citations_sites'
    end
  end

  def edit_citations_sites

    @site = Site.find(params[:id])

    render :update do |page|
      if !params["citation"].nil?
        params["citation"][:id].each do |c|
          @site.citations << Citation.find(c)
        end
      end
      page.replace_html 'edit_citations_sites', :partial => 'edit_citations_sites'
    end
  end

  def map 
    @site = Site.find(params[:id])
    respond_to do |format|
      format.html # map.html.erb

      format.xml  { render :xml => @site }
      format.csv  { render :csv => @site }
      format.json { render :json => @site }
    end
  end

  # GET /sites
  # GET /sites.xml
  def index
    # We have a lot of params and they or may not have to be
    # passed as conditions this is my way of adding them to conditions
    # if need be

    if params[:format].nil? or params[:format] == 'html'
      conditions = []
      conditions << ""

      # If we selected a citation we will list all associations first
      # so we do not want all the other list to include these citations
      @citation = Citation.find(session["citation"]) if !session["citation"].nil?
      #if !session["citation"].nil?
      if !@citation.nil? and @citation.sites.length > 0
        conditions[0] = "id not in (?)"
        conditions << @citation.sites.collect{ |x| x.id}
      else
        # we need an intial true statement so we do not have to mess with
        # the 'ands' below --hack--
        conditions[0] = "1 = 1"
      end

      # index also has a search!
      if !params[:lat].blank?
        conditions[0] += " AND lat > ? and lat < ?"
        conditions << params[:lat].to_f-1
        conditions << params[:lat].to_f+1
      end
      if !params[:lon].blank?
        conditions[0] += " and lon > ? and lon < ?"
        conditions << params[:lon].to_f-1
        conditions << params[:lon].to_f+1
      end
      if !params[:site].blank?
        conditions[0] += " AND (city like ? or state like ? or sitename like ?)"
        conditions << params[:site]
        conditions << params[:site]
        conditions << params[:site]
      end

      @sites = Site.paginate :page => params[:page], :per_page => 20, :conditions => conditions
    else
      conditions = {}
      params.each do |k,v|
        next if !Site.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @sites = Site.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb

      format.xml  { render :xml => @sites }
      format.csv  { render :csv => @sites }
      format.json { render :json => @sites }
    end
  end

  # GET /sites/1
  # GET /sites/1.xml
  def show
    @site = Site.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @site }
      format.csv  { render :csv => @site }
      format.json  { render :json => @site }
    end
  end

  # GET /sites/new
  # GET /sites/new.xml
  def new
    @site = Site.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @site }
      format.csv  { render :csv => @site }
      format.json  { render :json => @site }
    end
  end

  # GET /sites/1/edit
  def edit
    @site = Site.find(params[:id])
  end

  # POST /sites
  # POST /sites.xml
  def create
    @site = Site.new(params[:site])

    @site.user = current_user

    respond_to do |format|
      if @site.save
        # if they have a citation selected the relationship should be auto created!
        if !session["citation"].nil?
          @site.citations << Citation.find(session["citation"])
        end
        flash[:notice] = 'Site was successfully created.'
        format.html { redirect_to( sites_url ) }
        format.xml  { render :xml => @site, :status => :created, :location => @site }
        format.csv  { render :csv => @site, :status => :created, :location => @site }
        format.json  { render :json => @site, :status => :created, :location => @site }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @site.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @site.errors, :status => :unprocessable_entity }
        format.json  { render :json => @site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sites/1
  # PUT /sites/1.xml
  def update
    @site = Site.find(params[:id])

    params[:site].delete("user_id")

    respond_to do |format|
      if @site.update_attributes(params[:site])
        flash[:notice] = 'Site was successfully updated.'
        format.html { redirect_to(:action => :edit) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @site.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @site.errors, :status => :unprocessable_entity }
        format.json  { render :json => @site.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sites/1
  # DELETE /sites/1.xml
  def destroy
    @site = Site.find(params[:id])
    @site.citations.destroy
    @site.destroy

    respond_to do |format|
      format.html { redirect_to(sites_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end
end
