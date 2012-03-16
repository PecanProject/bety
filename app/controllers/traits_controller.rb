class TraitsController < ApplicationController
  before_filter :login_required, :except => [ :show ]
  before_filter :access_conditions

  layout 'application'

  require 'csv'
  require 'timeout'

  def execute_db_copy

    can_run = true
    if current_user.page_access_level <= 2
      finished = true

      pid = fork { `/usr/local/bin/db_copy.sh y` }
      begin
        Timeout.timeout(20) do
         Process.wait(pid)
      end
      rescue Timeout::Error
        logger.info 'db_copy.sh did not finished in time, killing it'
        Process.kill('TERM', pid)
        finished = false
      end
    else
      can_run = false
    end


    render :update do |page|
      if can_run
        if finished
          page << 'alert("db_copy finished successfully")'
       else
          page << 'alert("db_copy did not finish in time!")'
        end
      else
        page << 'alert("Sorry you are not authroized to run this script")'
      end
    end

  end

  def check_trait

    trait = Trait.new(params["trait"])
    count = params["count"]

    if count[/[^\d]/]
      count = 1
    else
      count = count.to_i
    end

    render :update do |page|
      if trait.valid?
        page["ok#{count}"].src = "/bety/images/greencheck.png"
      else
        page["ok#{count}"].src = "/bety/images/redcheck.png"
      end
    end
  end

  def add_row

    @count = params["count"]
    if @count[/[^\d]/]
      @count = nil
    else
      @count = @count.to_i
    end

    @treatments = Citation.find(session["citation"]).treatments rescue nil
    @sites = Citation.find(session["citation"]).sites rescue nil

    render :update do |page|
      if @count
        page.insert_html :before, 'place_holder', :partial => "new_multi_row"
        page.assign "count", @count + 1
      else
        page.assign "count", "2"
      end
    end
  end

  def create_multi
    respond_to do |format|
      format.html { redirect_to :action => "new_multi" }
      format.xml  { render :xml => @trait, :status => :created, :location => @trait }
      format.csv  { render :csv => @trait, :status => :created, :location => @trait }
    end
  end

  # GET /traits/new
  # GET /traits/new.xml
  def new_multi

    @treatments = Citation.find(session["citation"]).treatments rescue nil
    @sites = Citation.find(session["citation"]).sites rescue nil

    respond_to do |format|
      format.html # new.html.erb
      #format.xml  { render :xml => @trait }
      #format.csv  { render :csv => @trait }
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
     tmp_search = ""
     search_cond = ["", {} ]
     # symbols cannot be numbers...
     count = "a"
     @search.split(" ").each do |ss|
       if wildcards 
         ss = "%#{ss}%"
         tmp_search += ss + " "
       else
         tmp_search = ss
       end
       search_cond[1][count.to_sym] = ss
       search_cond[0] += " and " if count > "a"
       search_cond[0] += " ( " + Trait.column_names.collect {|x| "traits." + x }.join(" like :#{count} or ") + " like :#{count}"
       search_cond[0] += " or " + Citation.search_columns.join(" like :#{count} or ") + " like :#{count}"
       search_cond[0] += " or " + Variable.search_columns.join(" like :#{count} or ") + " like :#{count}"
       search_cond[0] += " or " + Specie.search_columns.join(" like :#{count} or ") + " like :#{count}"
       search_cond[0] += " or " + Site.search_columns.join(" like :#{count} or ") + " like :#{count}"
       search_cond[0] += " or " + Treatment.search_columns.join(" like :#{count} or ") + " like :#{count}" + ")"
       count = count.next
     end
     search = "Showing records for \"#{tmp_search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end

    if !session["citation"].nil?
      if search_cond.blank?
        search_cond = ["traits.citation_id = ?", session["citation"] ]
      else
        search_cond[0] += " and traits.citation_id = :citation"
        search_cond[1][:citation] = session["citation"]
      end
    end
    
    @traits = Trait.all_limited($checked,$access_level).paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :include => [:citation, :variable,:specie, :site,:treatment], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "traits.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end


  def trait_search
    @query = params[:symbol] || nil
    if !params[:symbol].nil? and !params[:cont].nil? and params[:symbol].length > 3
      @trait = Trait.all(:include => [:specie,:variable,:cultivar,:treatment,:citation], :conditions => ['species.scientificname like :query or species.genus like :query or species.AcceptedSymbol like :query or variables.name like :query or treatments.name like :query or citations.author like :query', {:query => "%" + @query + "%"} ],:limit => 100)
    else
      @trait = nil
    end

#Trait.all(:include => [:specie,:variable,:cultivar,:treatment,:citation]).collect { |p| [ p.specie_treat_cultivar, p.id ] }, {:selected => @covariate.trait_id.to_i }

    render :update do |page|
      if params[:symbol].length > 3
        if @trait.length == 100
          page.replace_html "results", "<h3>Search results for #{@query}. More then 100 results, please narrow your search.</h3>"
        else
          page.replace_html "results", "<h3>Search results for #{@query}</h3>"
        end
      else
        page.replace_html "results", "<h3>Search must be longer then 3 characters</h3>"
      end
      if @trait.nil?
        page.replace_html "#{params[:cont]}_trait_id", "<option value=''>There are no traits that match your query.</option>"
      else
        page.replace_html "#{params[:cont]}_trait_id", options_from_collection_for_select(@trait, :id, :select_default)
      end
    end

  end

  def access_level

    t = Trait.find(params[:id])
    
    render :update do |page|
      if t.update_attributes(params[:trait])
        page['access_level-'+t.id.to_s].visual_effect :pulsate
      else 
        page['access_level-'+t.id.to_s].visual_effect :shake
      end
    end
  end

  def checked
    y = Trait.find(params[:id])
    
    render :update do |page|
      if y.update_attributes(params[:trait])
        page.replace_html 'checked_notify-'+y.id.to_s, "<br />Updated to #{y.checked}"
      else 
        page.replace_html 'checked_notify-'+y.id.to_s, "<br />Something went wrong, not updated!"
      end
    end
  end


  # GET /traits
  # GET /traits.xml
  def index
    #@traits = Trait.find(:all, :conditions => ["variable_id IS NOT NULL AND treatment_id IS NOT NULL"], :limit => 100)

    if params[:format].nil? or params[:format] == 'html'
      if session["citation"].nil?
        conditions = ['1=1']
      else
        conditions = ["citation_id = ?", session["citation"] ]
      end
      @traits = Trait.all_limited($checked,$access_level,current_user.id).paginate :page => params[:page], :conditions => conditions, :include => [:site, :specie, :treatment], :order => 'date,sites.sitename,sites.country,sites.state,species.genus,species.species,treatments.name,treatments.definition',:per_page => 20
    else
      conditions = {}
      params.each do |k,v|
        next if !Trait.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @traits = Trait.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @traits }
      format.csv  { render :csv => @traits }
    end
  end

  # GET /traits/1
  # GET /traits/1.xml
  def show

    @trait = Trait.find(params[:id])

    if !logged_in?
      @trait = nil if !@trait.checked or @trait.access_level < 4
    elsif @trait.user_id == current_user.id or current_user.access_level == 1 or current_user.page_access_level <= 2
      #Every one can see what they created, makes the else easier. People in Dietz lab can see everything and 'Data Managers' can see everything
    else
      @trait = nil if !@trait.checked or current_user.access_level > @trait.access_level
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @trait }
      format.csv  { render :csv => @trait }
    end
  end

  # GET /traits/1
  # GET /traits/1.xml
  def nice

    @trait = Trait.find(params[:id])

    if !logged_in?
      @trait = nil if !@trait.checked or @trait.access_level < 4
    elsif @trait.user_id == current_user.id or current_user.access_level == 1 or current_user.page_access_level <= 2
      #Every one can see what they created, makes the else easier. People in Dietz lab can see everything and 'Data Managers' can see everything
    else
      @trait = nil if !@trait.checked or current_user.access_level > @trait.access_level
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @trait }
      format.csv  { render :csv => @trait }
    end
  end

  # GET /traits/new
  # GET /traits/new.xml
  def new
    if params[:id].nil?
      @trait = Trait.new
    else
      @trait_old = params[:id]
      @trait = Trait.find(@trait_old).clone
      @trait.specie.nil? ? @species = nil :  @species = [@trait.specie]
    end

#    @treatments = Treatment.find_by_sql ['select * from treatments where id in (select treatment_id from managements_treatments where management_id in (select id from managements where citation_id = ?))', session["citation"]]
#    @sites = Site.find_by_sql ['select * from sites where id in ( select site_id from citations_sites where citation_id = ?)', session["citation"]]

    @treatments = Citation.find(session["citation"]).treatments rescue nil
    @sites = Citation.find(session["citation"]).sites rescue nil

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trait }
      format.csv  { render :csv => @trait }
    end
  end

  # GET /traits/1/edit
  def edit
    @trait = Trait.find(params[:id])
    @trait.specie.nil? ? @species = nil : @species = [@trait.specie]
  end

  # POST /traits
  # POST /traits.xml
  def create
    # Allows a date to be entered with a year that shows we do not know the year.
    params[:trait]['date(1i)'] = "9999" if params[:trait]['date(1i)'].blank? and !params[:trait]['date(2i)'].blank?

    # If a time is entered it fails as Rails expects a date as well.
    if !params[:trait]['time(4i)'].blank? and !params[:trait]['time(5i)'].blank?
      params[:trait]['time(1i)'] = "9999"
      params[:trait]['time(2i)'] = "01"
      params[:trait]['time(3i)'] = "01"
    end

    if params[:trait]['time(4i)'].blank? and params[:trait]['time(4i)'].blank?
      params[:trait]['time(1i)'] = "9999"
      params[:trait]['time(2i)'] = "01"
      params[:trait]['time(3i)'] = "01"
      params[:trait]['time(4i)'] = "00"
      params[:trait]['time(5i)'] = "00"
    end

    @trait = Trait.new(params[:trait])

    @trait.user_id = current_user.id

    respond_to do |format|
      if @trait.save
        if !params[:covariate][:variable_id].blank?
          @covariate = Covariate.new(params[:covariate])
          @covariate.trait_id = @trait.id
        end
        if !@covariate.nil? and @covariate.save
          flash[:notice] = 'Trait & Covariate was successfully created.'
        else
          flash[:notice] = 'Trait was successfully created. No Covariate added'
        end
        format.html { redirect_to :action => "new", :id => @trait }
        format.xml  { render :xml => @trait, :status => :created, :location => @trait }
        format.csv  { render :csv => @trait, :status => :created, :location => @trait }
      else
        @treatments = Citation.find(session["citation"]).treatments rescue nil
        @sites = Citation.find(session["citation"]).sites rescue nil

        format.html { render :action => "new" }
        format.xml  { render :xml => @trait.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @trait.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /traits/1
  # PUT /traits/1.xml
  def update
    params[:trait]['date(1i)'] = "9999" if params[:trait]['date(1i)'].blank? and !params[:trait]['date(2i)'].blank?
    @trait = Trait.find(params[:id])

    respond_to do |format|
      if @trait.update_attributes(params[:trait])
        flash[:notice] = 'Trait was successfully updated.'
        format.html { redirect_to(@trait) }
        format.xml  { head :ok }
        format.csv  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @trait.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @trait.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /traits/1
  # DELETE /traits/1.xml
  def destroy
    @trait = Trait.find(params[:id])
    @trait.destroy

    respond_to do |format|
      format.html { redirect_to(traits_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
    end
  end
end
