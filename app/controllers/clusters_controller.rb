class ClustersController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

  def edit_clusters_sites
    @cluster = Cluster.access(current_user).find(params[:id])
    site = params[:site]

    if @cluster and site
      _site = Site.find(site)
      # If relationship exists we must want to remove it...
      if @cluster.sites.include?(_site)
        @cluster.sites.delete(_site)
        logger.info "deleted cluster:#{@cluster.id} - site:#{_site.id}"
      # Otherwise add it
      else
        @cluster.sites << _site
        logger.info "add cluster:#{@cluster.id} - site:#{_site.id}"
      end
    end

    @page = params[:page]

    # RAILS3 had to add the || '' in order for @search not be nil when params[:search] is nil
    @search = params[:search] || ''
    @searchparam = @search

    # If they search just a number it is probably an id, and we do not want to wrap that in wildcards.
    # @search.match(/\D/) ? wildcards = true : wildcards = false
    # We now ALWAYS use wildcards (unless the search is blank).
    wildcards = true

    if !@search.blank? 
      if wildcards 
        @search = "%#{@search}%"
      end
      search_cond = ["sitename LIKE :search", {:search => @search}] 
      search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end

    if @cluster and @search.blank?
      search = "Showing already related records"
      if @cluster.sites
        @sites = @cluster.sites.paginate :page => params[:page]
      end
    else
      @sites = Site.paginate :select => "*", :page => params[:page], :conditions => search_cond
    end

    render :update do |page|
      page.replace_html :sites_index_table, :partial => "edit_clusters_sites_table"
      page.replace_html :sites_search_term, search
    end
  end

  # GET /clusters
  # GET /clusters.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @clusters = Cluster.access(current_user).sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @clusters = Cluster.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @clusters }
      format.csv  { render :csv => @clusters }
      format.json  { render :json => @clusters }
    end
  end

  # GET /clusters/1
  # GET /clusters/1.xml
  def show
    @cluster = Cluster.access(current_user).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cluster }
      format.csv  { render :csv => @cluster }
      format.json  { render :json => @cluster }
    end
  end

  # GET /clusters/new
  # GET /clusters/new.xml
  def new
    @cluster = Cluster.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cluster }
      format.csv  { render :csv => @cluster }
      format.json  { render :json => @cluster }
    end
  end

  # GET /clusters/1/edit
  def edit
    @cluster = Cluster.access(current_user).find(params[:id])
    @sites = @cluster.sites.paginate :page => params[:page]
  end

  # POST /clusters
  # POST /clusters.xml
  def create
    @cluster = Cluster.new(params[:cluster])
    @cluster.user = current_user

    respond_to do |format|
      if @cluster.save
        format.html { redirect_to(@cluster, :notice => 'Cluster was successfully created.') }
        format.xml  { render :xml => @cluster, :status => :created, :location => @cluster }
        format.csv  { render :csv => @cluster, :status => :created, :location => @cluster }
        format.json  { render :json => @cluster, :status => :created, :location => @cluster }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @cluster.errors, :status => :unprocessable_entity }
        format.json  { render :json => @cluster.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /clusters/1
  # PUT /clusters/1.xml
  def update
    @cluster = Cluster.access(current_user).find(params[:id])

    respond_to do |format|
      if @cluster.update_attributes(params[:cluster])
        format.html { redirect_to(@cluster, :notice => 'Cluster was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { @sites = @cluster.sites.paginate :page => params[:page]; render :action => "edit" }
        format.xml  { render :xml => @cluster.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @cluster.errors, :status => :unprocessable_entity }
        format.json  { render :json => @cluster.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /clusters/1
  # DELETE /clusters/1.xml
  def destroy
    @cluster = Cluster.access(current_user).find(params[:id])
    @cluster.destroy

    respond_to do |format|
      format.html { redirect_to(clusters_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
