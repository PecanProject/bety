class SitegroupsController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

  def edit_sitegroups_sites
    @sitegroup = Sitegroup.access(current_user).find(params[:id])
    site = params[:site]

    if @sitegroup and site
      _site = Site.find(site)
      # If relationship exists we must want to remove it...
      if @sitegroup.sites.include?(_site)
        @sitegroup.sites.delete(_site)
        logger.info "deleted sitegroup:#{@sitegroup.id} - site:#{_site.id}"
      # Otherwise add it
      else
        @sitegroup.sites << _site
        logger.info "add sitegroup:#{@sitegroup.id} - site:#{_site.id}"
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

    if @sitegroup and @search.blank?
      search = "Showing already related records"
      if @sitegroup.sites
        @sites = @sitegroup.sites.paginate :page => params[:page]
      end
    else
      @sites = Site.paginate :select => "*", :page => params[:page], :conditions => search_cond
    end

    render :update do |page|
      page.replace_html :sites_index_table, :partial => "edit_sitegroups_sites_table"
      page.replace_html :sites_search_term, search
    end
  end

  # GET /sitegroups
  # GET /sitegroups.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @sitegroups = Sitegroup.access(current_user).sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @sitegroups = Sitegroup.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @sitegroups }
      format.csv  { render :csv => @sitegroups }
      format.json  { render :json => @sitegroups }
    end
  end

  # GET /sitegroups/1
  # GET /sitegroups/1.xml
  def show
    @sitegroup = Sitegroup.access(current_user).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sitegroup }
      format.csv  { render :csv => @sitegroup }
      format.json  { render :json => @sitegroup }
    end
  end

  # GET /sitegroups/new
  # GET /sitegroups/new.xml
  def new
    @sitegroup = Sitegroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @sitegroup }
      format.csv  { render :csv => @sitegroup }
      format.json  { render :json => @sitegroup }
    end
  end

  # GET /sitegroups/1/edit
  def edit
    @sitegroup = Sitegroup.access(current_user).find(params[:id])
    @sites = @sitegroup.sites.paginate :page => params[:page]
  end

  # POST /sitegroups
  # POST /sitegroups.xml
  def create
    @sitegroup = Sitegroup.new(params[:sitegroup])
    @sitegroup.user = current_user

    respond_to do |format|
      if @sitegroup.save
        format.html { redirect_to(@sitegroup, :notice => 'Sitegroup was successfully created.') }
        format.xml  { render :xml => @sitegroup, :status => :created, :location => @sitegroup }
        format.csv  { render :csv => @sitegroup, :status => :created, :location => @sitegroup }
        format.json  { render :json => @sitegroup, :status => :created, :location => @sitegroup }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @sitegroup.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @sitegroup.errors, :status => :unprocessable_entity }
        format.json  { render :json => @sitegroup.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sitegroups/1
  # PUT /sitegroups/1.xml
  def update
    @sitegroup = Sitegroup.access(current_user).find(params[:id])

    respond_to do |format|
      if @sitegroup.update_attributes(params[:sitegroup])
        format.html { redirect_to(@sitegroup, :notice => 'Sitegroup was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { @sites = @sitegroup.sites.paginate :page => params[:page]; render :action => "edit" }
        format.xml  { render :xml => @sitegroup.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @sitegroup.errors, :status => :unprocessable_entity }
        format.json  { render :json => @sitegroup.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sitegroups/1
  # DELETE /sitegroups/1.xml
  def destroy
    @sitegroup = Sitegroup.access(current_user).find(params[:id])
    @sitegroup.destroy

    respond_to do |format|
      format.html { redirect_to(sitegroups_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
