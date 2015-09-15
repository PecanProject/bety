# encoding: utf-8
# RAILS3 added above encoding (actually this is needed with Ruby 1.9.2)

class SpeciesController < ApplicationController
  before_filter :login_required, :except => [ :show ]
  helper_method :sort_column, :sort_direction

  require 'csv'

  # autocompletion for bulk upload wizard
  def bu_autocomplete
    # match against the initial portion of the scientificname only
    species = Specie.where("LOWER(scientificname) LIKE LOWER(?)", params[:term] + '%' ).to_a.map do |item|
       item.scientificname.squish
    end

    # don't show rows where scientificname is null or empty
    # TO-DO: eliminate these from the database and prevent them with a
    # constraint (or change to allow matching on other fields?)
    species.delete_if { |item| item.nil? || item.empty? }

    if species.empty?
      species = [ { label: "No matches", value: "" }]
    end

    respond_to do |format|
      format.json { render :json => species }
    end
  end

  def search_pfts
    @species = Specie.find(params[:id])

    # the "sorted_order" call is mainly so "search" has the joins it needs
    @pfts = Pft.sorted_order("#{sort_column('pfts','updated_at')} #{sort_direction}").search(params[:search_pfts])

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  def species_search
    @query = params[:symbol] || nil

    # Strip anything not A-Z, a-z, 0-9, the underscore, or whitespace.
    @query.gsub!(/[^\w\s]+/, '')

    if !params[:symbol].nil? and !params[:cont].nil? and params[:symbol].length > 3
      @species = Specie.where('LOWER(scientificname) LIKE LOWER(:query) OR LOWER(genus) LIKE LOWER(:query) OR LOWER("AcceptedSymbol") LIKE LOWER(:query) OR LOWER(commonname) LIKE LOWER(:query)' +
                              ' OR LOWER(scientificname) LIKE LOWER(:query2) OR LOWER(genus) LIKE LOWER(:query2) OR LOWER("AcceptedSymbol") LIKE LOWER(:query2) OR LOWER(commonname) LIKE LOWER(:query2)', 
                              {:query => @query + "%", :query2 => "%" + @query + "%"}).limit(100).order("scientificname")
      @species.uniq!
    else
      @species = []
    end

    render :update do |page|
      if params[:cont] == "species"
        page.replace_html "search_results", :partial => 'search', :object => @species
      else
        if @species.empty?
          page.replace_html "#{params[:cont]}_specie_id", "<option value=''>There are no species that match your query.</option>"
        else
          page.replace_html "#{params[:cont]}_specie_id", options_from_collection_for_select(@species, :id, :select_default)
        end
      end
      if params[:symbol].length > 3
        page.replace_html "results", "<h3>Search results for #{sanitize(@query)}</h3>"
      else
        page.replace_html "results", "<h3>Search must be longer then 3 characters</h3>"
      end
    end

#    render :partial => 'species/species_search'
  end


  def rem_pfts_species
    @species = Specie.find(params[:id])
    @pft = Pft.find(params[:pft])

    @species.pfts.delete(@pft)

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  def add_pfts_species

    @species = Specie.find(params[:id])
    @pft = Pft.find(params[:pft])

    @species.pfts << @pft

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end




  # GET /species
  # GET /species.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @species = Specie.sorted_order("#{sort_column('species','scientificname')} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(Specie)
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @species = Specie.api_search(params)
      log_searches(Specie.method(:api_search), params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @species }
      format.csv  { render :csv => @species }
      format.json  { render :json => @species }
    end
  end

  # GET /species/1
  # GET /species/1.xml
  def show
    @specie = Specie.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @specie }
      format.csv  { render :csv => @specie }
      format.json  { render :json => @specie }
    end
  end

  # GET /species/new
  # GET /species/new.xml
  def new
    @specie = Specie.new

    @specie = Specie.find(params[:id]) if !params[:id].nil?

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @specie }
      format.csv  { render :csv => @specie }
      format.json  { render :json => @specie }
    end
  end

  # GET /species/1/edit
  def edit
    @species = Specie.find(params[:id])
    @pfts = @species.pfts

    respond_to do |format|
      format.html
      format.js {
        render layout: false
      }
    end
  end

  # POST /species
  # POST /species.xml
  def create
    @specie = Specie.new(params[:specie])

    # Set the scientificname to genus + species if blank, or use the scientificname to set genus/species.
    if @specie.scientificname.blank?
      @specie.scientificname = "#{@specie.genus} #{@specie.species}" 
    else
      sn = @specie.scientificname.split(" ")
      if sn.length >= 2
        if @specie.genus.blank?
          @specie.genus = sn[0]
        end
        #If species starts with '×' it is not the species, ignore it. Species names might have spaces...
        if @specie.species.blank? and !sn[1][/×/]
          @specie.species = sn[1..-1].join(" ")
        end
      end
    end
    respond_to do |format|
      if @specie.save
        flash[:notice] = 'Specie was successfully created.'
        format.html { redirect_to(@specie) }
        format.xml  { render :xml => @specie, :status => :created, :location => @specie }
        format.csv  { render :csv => @specie, :status => :created, :location => @specie }
        format.json  { render :json => @specie, :status => :created, :location => @specie }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @specie.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @specie.errors, :status => :unprocessable_entity }
        format.json  { render :json => @specie.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /species/1
  # PUT /species/1.xml
  def update
    @species = Specie.find(params[:id])

    respond_to do |format|
      if @species.update_attributes(params[:specie])
        flash[:notice] = 'Specie was successfully updated.'
        format.html { redirect_to( edit_species_path(@species) ) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { 
          @pfts = @species.pfts
          render :action => "edit" }
        format.xml  { render :xml => @species.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @species.errors, :status => :unprocessable_entity }
        format.json  { render :json => @species.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /species/1
  # DELETE /species/1.xml
  def destroy
    @specie = Specie.find(params[:id])
    @specie.destroy

    respond_to do |format|
      format.html { redirect_to(species_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
