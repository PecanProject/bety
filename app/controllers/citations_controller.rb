class CitationsController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

  require 'csv'

  # general autocompletion
  def autocomplete
    citations = search_model(Citation.order('author'), %w( author title ), params[:term])

    citations = citations.to_a.map do |item|
      {
        # show variable name and site name in suggestions
        label: item.autocomplete_label,
        value: item.id
      }
    end

    citations = citations.unshift({ label: "[no value]", value: nil })

    respond_to do |format|
      format.json { render :json => citations }
    end
  end

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
          next if c.empty?
          @citation.sites << Site.find(c)
        end
        page.replace_html 'edit_citations_sites', :partial => 'edit_citations_sites'
      else
        page.replace_html 'edit_citations_sites', :partial => 'edit_citations_sites'
      end
    end
  end

  # autocompletion for bulk upload wizard
  def bu_autocomplete
    search_term = params[:term]

    # match against any portion of the author, year, title, or doi
    match_string = '%' + search_term + '%'

    filtered_citations = Citation.where("LOWER(author) LIKE LOWER(:match_string) OR year::text LIKE :match_string OR LOWER(title) LIKE LOWER(:match_string) OR LOWER(doi) LIKE LOWER(:match_string)",
                                        match_string: match_string)

    if filtered_citations.size > 0 || search_term.size > 1
      citations = filtered_citations
      # else if there are no matches and the user has only typed one letter, just return everything
    end

    citations = citations.to_a.map do |item|
      {
        label: "#{item.to_s} #{item.doi.blank? ? "" : "(doi: #{item.doi})"}",
        value: item.id
      }
    end

    if citations.empty?
      citations = [ { label: "No matches", value: "" }]
    end

    respond_to do |format|
      format.json { render :json => citations }
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
