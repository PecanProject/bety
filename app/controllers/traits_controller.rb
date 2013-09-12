class TraitsController < ApplicationController
  before_filter :login_required, :except => [ :show ]
  helper_method :sort_column, :sort_direction

  require 'csv'
  require 'timeout'

  def trait_search
    @query = params[:symbol] || nil
    if !params[:symbol].nil? and !params[:cont].nil? and params[:symbol].length > 3
      @trait = Trait.all_limited(current_user).includes([:specie,:variable,:cultivar,:treatment,:citation]).where('species.scientificname like :query or species.genus like :query or species.AcceptedSymbol like :query or variables.name like :query or treatments.name like :query or citations.author like :query', {:query => "%" + @query + "%"}).limit(100)
    else
      @trait = nil
    end


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

    t = Trait.all_limited(current_user).find(params[:id])

    t.access_level = params[:trait][:access_level] if t
    
    render :update do |page|
      if t and t.save
        page['access_level-'+t.id.to_s].visual_effect :pulsate
      else 
        page['access_level-'+t.id.to_s].visual_effect :shake
      end
    end
  end

  def checked
    t = Trait.all_limited(current_user).find(params[:id])
    t.current_user = current_user
    t.checked = params[:trait][:checked] if t
   
    render :update do |page|
      if t and t.save
        page.replace_html 'checked_notify-'+t.id.to_s, "<br />Updated to #{t.checked}"
      else 
        page.replace_html 'checked_notify-'+t.id.to_s, "<br />Something went wrong, not updated!"
      end
    end
  end


  # GET /traits
  # GET /traits.xml
  def index
    @traits = Trait.all_limited(current_user)
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @traits = @traits.citation(session["citation"]).sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(@traits.citation(session["citation"]).search(params[:search]).to_sql)
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @traits = @traits.exclude_api.api_search(params)
      log_searches(@traits.exclude_api.api_search(params).to_sql)
    end

    respond_to do |format|
      format.html 
      format.js 
      format.xml  { render :xml => @traits }
      format.json { render :json => @traits }
      format.csv  { render :csv => @traits, :style => (params[:style] ||= 'default').to_sym }
    end
  end

  # GET /traits/1
  # GET /traits/1.xml
  def show
    # find_by_id prevents errors when they do not have access
    @trait = Trait.all_limited(current_user).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @trait }
      format.json { render :json => @trait }
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
      @trait = Trait.all_limited(current_user).find(@trait_old).clone
      @trait.specie.nil? ? @species = nil :  @species = [@trait.specie]
    end

    @citation = Citation.find_by_id(session["citation"])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @trait }
      format.csv  { render :csv => @trait }
    end
  end

  # GET /traits/1/edit
  def edit
    @trait = Trait.all_limited(current_user).find(params[:id])
    @trait.specie.nil? ? @species = nil : @species = [@trait.specie]
  end

  # POST /traits
  # POST /traits.xml
  def create
    @trait = Trait.new(params[:trait])

    @trait.user_id = current_user.id

    respond_to do |format|
      if @trait.save
        params[:covariate].each do |covariate|
          unless covariate[:variable_id].blank?
            @covariate = Covariate.new(covariate)
            @trait.covariates << @covariate
          end
        end
        flash[:notice] = "Trait was successfully created. #{@trait.covariates.length} covariate(s) added"
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
    @trait = Trait.all_limited(current_user).find(params[:id])
    @trait.current_user = current_user #Used to validate that they are allowed to change checked

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
    @trait = Trait.all_limited(current_user).find(params[:id])
    @trait.destroy

    respond_to do |format|
      format.html { redirect_to(traits_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
    end
  end

end
