class CitationsController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

  require 'csv'

  def rem_citations_sites
    @citation = Citation.find(params[:id])
    @site = Site.find(params[:site])

    render :update do |page|
      if @citation.sites.delete(@site)
        page.replace_html 'edit_citations_sites', :partial => 'edit_citations_sites'
      else
        page.replace_html 'edit_citations_sites', :partial => 'edit_citations_sites'
      end
    end
  end

  def edit_citations_sites

    @citation = Citation.find(params[:id])

    render :update do |page|
      if !params[:site].nil?
        params[:site][:id].each do |c|
          @citation.sites << Site.find(c)
        end
        page.replace_html 'edit_citations_sites', :partial => 'edit_citations_sites'
      else
        page.replace_html 'edit_citations_sites', :partial => 'edit_citations_sites'
      end
    end
  end

  # GET /citations
  # GET /citations.xml
  def index

    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @citations = Citation.sorted_order("#{sort_column('citations','author')} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(Citation)
    else
      @citations = Citation.api_search(params)
      log_searches(Citation.method(:api_search), params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js 
      format.xml  { render :xml => @citations }
      format.csv  { render :csv => @citations }
      format.json  { render :json => @citations }
    end
  end

  # GET /citations/1
  # GET /citations/1.xml
  def show
    @citation = Citation.where(:id => params[:id]).includes(params[:include]).first

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @citation }
      format.csv  { render :csv => @citation }
      format.json  { render :json => @citation }
    end
  end

  # GET /citations/new
  # GET /citations/new.xml
  def new
    @citation = Citation.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /citations/1/edit
  def edit
    @citation = Citation.find(params[:id])
  end

  # POST /citations
  # POST /citations.xml
  def create
    @citation = Citation.new(params[:citation])

    @citation.user = current_user

    respond_to do |format|
      if @citation.save
        session['citation'] = @citation.id
        flash[:notice] = 'Citation was successfully created.'
        format.html { redirect_to sites_path }
        format.xml  { render :xml => @citation, :status => :created, :location => @citation }
        format.csv  { render :csv => @citation, :status => :created, :location => @citation }
        format.json  { render :json => @citation, :status => :created, :location => @citation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @citation.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @citation.errors, :status => :unprocessable_entity }
        format.json  { render :json => @citation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /citations/1
  # PUT /citations/1.xml
  def update
    @citation = Citation.find(params[:id])

    params["citation"].delete("user_id")

    respond_to do |format|
      if @citation.update_attributes(params[:citation])
        flash[:notice] = 'Citation was successfully updated.'
        format.html { redirect_to(:action => :edit) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @citation.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @citation.errors, :status => :unprocessable_entity }
        format.json  { render :json => @citation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /citations/1
  # DELETE /citations/1.xml
  def destroy
    @citation = Citation.find(params[:id])
    @citation.sites.destroy
    @citation.destroy

    # Someone might erase a citation they (or someone else) is 'linked' to so remove it for them
    # if necessary and in the layou we check if the citation exists and if not unlink them.
    session['citation'] = nil if session['citation'] == params[:id]

    respond_to do |format|
      format.html { redirect_to(citations_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
