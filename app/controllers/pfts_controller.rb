class PftsController < ApplicationController
  before_filter :login_required
  helper_method :sort_column, :sort_direction

  require 'csv'
  
  # restful-authentication override 
  def access_denied
    flash[:notice] = 'You have insufficient permissions to create new PFTs'
    redirect_to :action => "index"
  end

  def rem_pfts_priors
    @pft = Pft.find(params[:id])
    @prior = Prior.find(params[:prior])

    render :update do |page|
      if @pft.priors.delete(@prior)
        page.replace_html 'edit_pfts_priors', :partial => 'edit_pfts_priors'
      else
        page.replace_html 'edit_pfts_priors', :partial => 'edit_pfts_priors'
      end
    end
  end

  def edit_pfts_priors
    @pft = Pft.find(params[:id])

    render :update do |page|
      if !params[:prior].nil?
        params[:prior][:id].each do |c|
          @pft.priors << Prior.find(c)
        end
        page.replace_html 'edit_pfts_priors', :partial => 'edit_pfts_priors'
      else
        page.replace_html 'edit_pfts_priors', :partial => 'edit_pfts_priors'
      end
    end
  end

  def edit2_pfts_species
    @pft = Pft.find(params[:id])
    species = params[:species]

    if @pft and species
      _species = Specie.find(species)
      # If relationship exists we must want to remove it...
      if @pft.specie.include?(_species)
        @pft.specie.delete(_species)
        logger.info "deleted pft:#{@pft.id} - species:#{_species.id}"
      # Otherwise add it
      else
        @pft.specie << _species
        logger.info "add pft:#{@pft.id} - species:#{_species.id}"
      end
    end

    @page = params[:page]

    # RAILS3 had to add the || '' in order for @search not be nil when params[:search] is nil
    @search = params[:search] || ''
    # If they search just a number it is probably an id, and we do not want to wrap that in wildcards.
    @search.match(/\D/) ? wildcards = true : wildcards = false

    if !@search.blank? 
      if wildcards 
       @search = "%#{@search}%"
     end
     search_cond = [Specie.column_names.collect {|x| "species." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end

    if @pft and @search.blank?
      search = "Showing already related records"
      @species = @pft.specie.paginate :page => params[:page]
    else
      @species = Specie.paginate :select => "id,scientificname", :page => params[:page], :conditions => search_cond
    end

    render :update do |page|
      page.replace_html :index_table, :partial => "edit2_pfts_species_table"
      page.replace_html :search_term, search
    end
  end

  def make_clone
    orig_pft = Pft.find(params[:id])
    pft = orig_pft.make_deep_clone

    respond_to do |format|
      format.html { redirect_to(pft_url(pft)) }
    end
  end

  # GET /pfts
  # GET /pfts.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @pfts = Pft.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(Pft)
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @pfts = Pft.api_search(params)
      log_searches(Pft.method(:api_search), params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @pfts }
      format.csv  { render :csv => @pfts }
      format.json  { render :json => @pfts }
    end
  end

  # GET /pfts/1
  # GET /pfts/1.xml
  def show
    @pft = Pft.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @pft }
      format.csv  { render :csv => @pft }
      format.json  { render :json => @pft }
    end
  end

  # GET /pfts/new
  # GET /pfts/new.xml
  def new 
    @pft = Pft.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pft }
      format.csv  { render :csv => @pft }
      format.json  { render :json => @pft }
    end
  end

  # GET /pfts/1/edit
  def edit
    @pft = Pft.find(params[:id])
    @species = @pft.specie.paginate :page => params[:page]
  end

  # POST /pfts
  # POST /pfts.xml
  def create
    @pft = Pft.new(params[:pft])

    respond_to do |format|
      if @pft.save
        flash[:notice] = 'Pft was successfully created.'
        format.html { redirect_to( edit_pft_path(@pft)) }
        format.xml  { render :xml => @pft, :status => :created, :location => @pft }
        format.csv  { render :csv => @pft, :status => :created, :location => @pft }
        format.json  { render :json => @pft, :status => :created, :location => @pft }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @pft.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @pft.errors, :status => :unprocessable_entity }
        format.json  { render :json => @pft.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pfts/1
  # PUT /pfts/1.xml
  def update
    @pft = Pft.find(params[:id])

    respond_to do |format|
      if @pft.update_attributes(params[:pft])
        flash[:notice] = 'Pft was successfully updated.'
        format.html { redirect_to(@pft) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @pft.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @pft.errors, :status => :unprocessable_entity }
        format.json  { render :json => @pft.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pfts/1
  # DELETE /pfts/1.xml
  def destroy
    @pft = Pft.find(params[:id])
    @pft.priors.destroy
    @pft.destroy

    respond_to do |format|
      format.html { redirect_to(pfts_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
