class YieldsController < ApplicationController
  before_filter :login_required, :except => [ :show ]
#  before_filter :access_conditions

  layout 'application'

  require 'csv'

  def checked
    y = Yield.all_limited(current_user).find_by_id(params[:id])
    
    render :update do |page|
      if y.update_attributes(params[:y])
        page.replace_html 'checked_notify-'+y.id.to_s, "<br />Updated to #{y.checked}"
      else 
        page.replace_html 'checked_notify-'+y.id.to_s, "<br />Something went wrong, not updated!"
      end
    end
  end

  def access_level

    y = Yield.all_limited(current_user).find_by_id(params[:id])
    
    render :update do |page|
      if y.update_attributes(params[:yield])
        page['access_level-'+y.id.to_s].visual_effect :pulsate
      else 
        page['access_level-'+y.id.to_s].visual_effect :shake
      end
    end
  end

  def search
    sort = params[:sort]

    @page = params[:page]
    @current_sort = params[:current_sort]
    params[:current_sort_order].match(/true/) ? @current_sort_order = true : @current_sort_order = false

    @search = params[:search]
    # If they search just a number it is probably an id, and we do not want to wrap that in wildcards.
    @search.match(/\D/) ? wildcards = true : wildcards = false

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
     search_cond = [ "( " + Yield.column_names.collect {|x| "yields." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search_cond[0] += " or " + Citation.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Cultivar.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Specie.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Site.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Treatment.search_columns.join(" like :search or ") + " like :search" + " )"
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end

    if !session["citation"].nil?
      if search_cond.blank?
        search_cond = ["yields.citation_id = ?", session["citation"] ]
      else
        search_cond[0] += " and yields.citation_id = :citation"
        search_cond[1][:citation] = session["citation"]
      end
    end 

    @yields = Yield.all_limited(current_user).paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :include => [:citation, :cultivar, :specie, :site, :treatment], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "yields.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end


  # GET /yields/csv
  # GET /yields/csv.xml
  def csv
    @yield = Yield.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @yield }
      format.csv  { render :csv => @yield }
    end
  end

  # GET /yields
  # GET /yields.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      if session["citation"].nil?
        conditions = ['1=1']
      else
        conditions = ["citation_id = ?", session["citation"] ]
      end
      @yields = Yield.all_limited(current_user).paginate :page => params[:page], :conditions => conditions, :include => [:site, :specie, :treatment], :order => 'species.genus,species.species,treatments.name,treatments.definition',:per_page => 20
    else
      conditions = {}
      params.each do |k,v|
        next if !Yield.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @yields = Yield.all_limited(current_user).all(:conditions => conditions)
    end 
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @yields }
      format.csv  { render :csv => @yields, :style => (params[:style] ||= "default").to_sym }
    end
  end

  # GET /yields/1
  # GET /yields/1.xml
  def show
    @yield = Yield.all_limited(current_user).find_by_id(params[:id])

    if !logged_in?
      @yield = nil if !@yield.checked or @yield.access_level < 4
    elsif @yield.user_id == current_user.id or current_user.access_level == 1 or current_user.page_access_level <= 2
      #Every one can see what they created, makes the else easier. People in Dietz lab can see everything and 'Datta Managers' can see everything
    else
      @yield = nil if !@yield.checked or current_user.access_level > @yield.access_level
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @yield }
      format.csv  { render :csv => @yield }
    end
  end

  # GET /yields/new
  # GET /yields/new.xml
  def new
    if params[:id].nil?
      @yield = Yield.new
    else
      @yield = Yield.all_limited(current_user).find_by_id(params[:id]).clone
      @yield.specie.nil? ? @species = nil : @species = [@yield.specie]
    end

    @citation = Citation.find_by_id(session["citation"])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @yield }
      format.csv  { render :csv => @yield }
    end
  end

  # GET /yields/1/edit
  def edit
    @yield = Yield.all_limited(current_user).find_by_id(params[:id])
    @yield.specie.nil? ? @species = nil : @species = [@yield.specie]
  end

  # POST /yields
  # POST /yields.xml
  def create
    params[:yield]['date(1i)'] = "9999" if params[:yield]['date(1i)'].blank? and !params[:yield]['date(2i)'].blank?

    @yield = Yield.new(params[:yield])

    # they only wanted one drop down for cultivar/species so we have to get 
    # their id's if they were selected.

    #if !params[:cultivar_specie_id].empty?
    #  @yield.cultivar_id = params[:cultivar_specie_id].match('(\d*)-')[1]
    #  @yield.specie_id = params[:cultivar_specie_id].match('-(\d*)')[1]
    #end

    # they can also enter the date in julian format, so if they do overwrite the
    # other date field
    if !params[:juliandate].nil? and !params[:juliandate].empty?
      @yield.date = Date.ordinal(params[:julianyear].to_f, params[:julianday].to_f)
    end

    @yield.user_id = current_user.id

    logger.info "Current user: #{current_user.id}"

    respond_to do |format|
      if @yield.save
        flash[:notice] = 'Yield was successfully created.'
        format.html { redirect_to :action => "new", :id => @yield }
        format.xml  { render :xml => @yield, :status => :created, :location => @yield }
        format.csv  { render :csv => @yield, :status => :created, :location => @yield }
      else
        @treatments = Citation.find_by_id(session["citation"]).treatments rescue nil
        @sites = Citation.find_by_id(session["citation"]).sites rescue nil
        format.html { render :action => "new" }
        format.xml  { render :xml => @yield.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @yield.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /yields/1
  # PUT /yields/1.xml
  def update
    @yield = Yield.all_limited(current_user).find_by_id(params[:id])

    respond_to do |format|
      if @yield.update_attributes(params[:yield])
        flash[:notice] = 'Yield was successfully updated.'
        format.html { redirect_to(@yield) }
        format.xml  { head :ok }
        format.csv  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @yield.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @yield.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /yields/1
  # DELETE /yields/1.xml
  def destroy
    @yield = Yield.all_limited(current_user).find_by_id(params[:id])
    @yield.destroy

    respond_to do |format|
      format.html { redirect_to(yields_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
    end
  end
end
