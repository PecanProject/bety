class CitationsController < ApplicationController

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
        logger.info "here"
        @current_sort = sort
        @current_sort_order = false
      end
    end

    if !@search.blank?
      if wildcards 
       @search = "%#{@search}%"
     end
     search_cond = [Citation.column_names.collect {|x| "citations." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @citations = Citation.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "citations.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end



   #Replaced 20111108 - citations/index
#  def search
#
#    author, species = nil
#
#    @phrase = params[:search]
#    conditions = ["", {}]
#    @match = []
#
#    @phrase.split(",").each do |phrase|
#      author = phrase.split("=")[1] if phrase.split("=")[0] =~ /[a]/
#      species = phrase.split("=")[1] if phrase.split("=")[0] =~ /[s]/
#    end
#
#    if author
#      conditions[0] += '(author like :author or title like :author)'
#      conditions[1][:author] = "%" + author + "%" 
#      @match += Citation.all(:conditions => conditions, :order => :author, :limit => 100) if @phrase.length > 3 and (author or species)
#    end
#    if species
#      joins = { :traits => :specie, :yields => :specie }
#      conditions[0] += ' or ' if !conditions[0].blank?
#      conditions[0] += '(species.genus like :species or species.commonname like :species or species_yields.genus like :species or species_yields.commonname like :species)'
#      conditions[1][:species] = "%" +  species + "%"
#      @match += Citation.all(:joins => joins, :conditions => conditions, :order => :author, :limit => 100) if @phrase.length > 3
#    end
#
#    logger.info conditions.to_yaml
#
#    @match.uniq!
#
#    render(:layout => false)
#  end

#  def csv_import 
#    @parsed_file=CSV::Reader.parse(params[:dump][:file])
#    n=0
#
#    errors = Hash.new
#
#    @parsed_file.each  do |row|
#      error = ""
#      c=Citations.new
#      c.author=row[0] or error += "Name, " 
#      c.year=row[1] or error += "Year, "
#      c.title=row[2] or error += "Title, " 
#      c.journal=row[3] or error += "Journal, " 
#      c.vol=row[4] 
#      c.pg=row[5] 
#      c.url=row[6] 
#      c.pdf=row[7] 
#      if c.save
#        if !error.empty?
#          @error = Error_log.new
#          @error.record_id = c.id
#          @error.description = error
#          @error.type = "Citation"
#          @error.save
#          errors << c.id
#        end
#        n=n+1
#        GC.start if n%50==0
#      end
#    end
#    flash[:notice]="CSV Import Successful,  #{n} new records added"
#
#    if errors.empty? 
#      redirect_to :action => "index"
#    else
#      redirect_to :action => "csv_missing", :errors => errors
#    end
#  end

  #produce a list of list of csv import file missing info
#  def csv_missing
#    @citations = Citations.find(:all, :conditions => ["id in (?)", params[:errors].collect { |p| p.to_i } ])
#    @errors = params[:errors]
#
#    respond_to do |format|
#      format.html 
#      format.xml  { render :xml => @citations }
#      format.csv  { render :csv => @citations }
#      format.csv  { render :csv => @citations }
#    end
#  end


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
      @citations = Citation.paginate :page => params[:page], :order => "author"
    else
      conditions = {}
      params.each do |k,v|
        next if !Citation.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @citations = Citation.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @citations }
      format.csv  { render :csv => @citations }
      format.json  { render :json => @citations }
    end
  end

  # GET /citations/1
  # GET /citations/1.xml
  def show
    @citation = Citation.find(params[:id])

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
