class TraitsController < ApplicationController
  before_action :login_required, :except => [ :show ]
  helper_method :sort_column, :sort_direction

  require 'csv'
  require 'timeout'

  def trait_search
    @query = params[:symbol] || nil
    if !params[:symbol].nil? and !params[:cont].nil? and params[:symbol].length > 3

      @trait = Trait.all_limited(current_user).
        includes([:specie,:variable,:cultivar,:treatment,:citation]).
        references([:specie,:variable,:treatment,:citation]).
        where(%q{   species.scientificname LIKE :query
                 OR species.genus LIKE :query
                 OR species."AcceptedSymbol" LIKE :query
                 OR variables.name LIKE :query
                 OR treatments.name LIKE :query
                 OR citations.author LIKE :query},
              {:query => "%" + @query + "%"}).
        limit(100)

    else
      @trait = nil
    end

    if params[:symbol].length > 3
      if @trait.length == 100
        @message = "<h3>Search results for #{@query}. More then 100 results, please narrow your search.</h3>"
      else
        @message = "<h3>Search results for #{@query}</h3>"
      end
    else
      @message = "<h3>Search must be longer then 3 characters</h3>"
    end

    if @trait.nil?
      @options = "<option value=''>There are no traits that match your query.</option>"
    else
      @options = ActionController::Base.helpers.options_from_collection_for_select(@trait, :id, :select_default)
    end

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  def access_level

    t = Trait.all_limited(current_user).find(params[:id])
    t.current_user = current_user
    t.access_level = params[:trait][:access_level] if t

    @element_id = "access_level-#{t.id}"

    if t && t.save
      @saved = true
    else
      @saved = false
    end

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  def checked
    id = params[:id]
    t = Trait.all_limited(current_user).find_by_id(id)

    if t
      t.current_user = current_user
      t.checked = params[:trait][:checked]
    end

    @element_id = "checked_notify-#{id}"

    if t && t.save
      @message = "<br />Updated to #{t.checked}"
    else
      @message = "<br />Something went wrong, not updated!"
    end

    respond_to do |format|
      format.js {
        render layout: false
      }
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
      @trait = Trait.all_limited(current_user).find(@trait_old).dup
      @trait.specie.nil? ? @species = nil :  @species = [@trait.specie]
    end

    @citation = Citation.find_by_id(session["citation"])
    @new_covariates = [Covariate.new]
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
    @citation = @trait.citation
    @new_covariates = [Covariate.new]
  end

  # POST /traits
  # POST /traits.xml
  def create
    @trait = Trait.new(params[:trait])

    @trait.user_id = current_user.id

    @new_covariates = []
    respond_to do |format|
      Trait.transaction do
        saved_covariates = []
        @trait.save
        params[:covariate].each do |c|
          unless c[:variable_id].blank?
            @covariate = Covariate.new(c)
            @new_covariates << @covariate
            if @covariate.save
              # these "saved" covariates are rolled back if any save errors occur
              saved_covariates << @covariate
            else
              @trait.errors.add(:covariates, (@covariate.errors.get(:level))[0])
            end
          end
        end
        if @trait.errors.size > 0
          raise StandardError, "Trait could not be created. Please see error messages"
        else
          @trait.covariates += saved_covariates
        end
      end
      flash[:notice] = "Trait was successfully created. #{@trait.covariates.length} covariate(s) added"
      format.html { redirect_to(@trait) }
      format.xml  { head :ok }
      format.csv  { head :ok }
    end
  rescue StandardError, ActiveRecord::StatementInvalid => e
    logger.info(e)
    flash[:error] = e.message
    @citation = @trait.citation
    if @new_covariates.empty?
      @new_covariates = [Covariate.new]
    end
    respond_to do |format|
      format.html { render :action => "new" }
      format.xml  { render :xml => @trait.errors, :status => :unprocessable_entity }
      format.csv  { render :csv => @trait.errors, :status => :unprocessable_entity }
    end
  end


  # PUT /traits/1
  # PUT /traits/1.xml
  def update
    @trait = Trait.all_limited(current_user).find(params[:id])
    @trait.current_user = current_user #Used to validate that they are allowed to change checked
    @new_covariates = []
    respond_to do |format|
      Trait.transaction do
        saved_covariates = []
        @trait.update_attributes(params[:trait])
        params[:covariate].each do |c|
          unless c[:variable_id].blank?
            @covariate = Covariate.new(c)
            @new_covariates << @covariate
            if @covariate.save
              # these "saved" covariates are rolled back if any save errors occur
              saved_covariates << @covariate
            else
              @trait.errors.add(:covariates, (@covariate.errors.get(:level))[0])
            end
          end
        end
        if @trait.errors.size > 0
          raise StandardError, "Trait could not be saved. Please see error messages"
        else
          @trait.covariates += saved_covariates
        end
      end
      flash[:notice] = 'Trait was successfully updated.'
      format.html { redirect_to(@trait) }
      format.xml  { head :ok }
      format.csv  { head :ok }
    end
  rescue StandardError, ActiveRecord::StatementInvalid => e
    logger.info(e)
    flash[:error] = e.message
    @citation = @trait.citation
    if @new_covariates.empty?
      @new_covariates = [Covariate.new]
    end
    respond_to do |format|
      format.html { render :action =>"edit" }
      format.xml  { render :xml => @trait.errors, :status => :unprocessable_entity }
      format.csv  { render :csv => @trait.errors, :status => :unprocessable_entity }
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

  def unlink_covariate
    @trait = Trait.all_limited(current_user).find(params[:id])
    Covariate.find(params[:covariate]).destroy
    respond_to do |format|
      format.js {
        render layout: false
      }
      format.html { head :ok }
      format.xml  { head :ok }
      format.csv  { head :ok }
    end

  end

end
