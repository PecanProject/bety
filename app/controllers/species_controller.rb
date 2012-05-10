class SpeciesController < ApplicationController
  before_filter :login_required, :except => [ :show ]

  layout 'application'

  require 'csv'

  def species_search
    @query = params[:symbol] || nil

    #Strip anything not A-Z, 0-9
    @query.gsub!(/[^\w\s]+/,'')

    if !params[:symbol].nil? and !params[:cont].nil? and params[:symbol].length > 3
      @species = Specie.all(:conditions => ['scientificname like :query or genus like :query or AcceptedSymbol like :query or commonname like :query or scientificname like :query2 or genus like :query2 or AcceptedSymbol like :query2 or commonname like :query2', {:query => @query + "%", :query2 => "%" + @query + "%"} ],:limit => 100,:order => "scientificname")
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
    @pft = Pft.find(params[:id])
    @species = Specie.find(params[:specie])

    render :update do |page|
      @pft.specie.delete(@species)
      page.replace_html 'edit_pfts_species', :partial => 'edit_pfts_species'
    end
  end

  def edit_pfts_species

    @species = Specie.find(params[:id])

    render :update do |page|
      if !params[:pft].nil?
        params[:pft][:id].each do |c|
          @species.pfts << Pft.find(c)
        end
      end
      page.replace_html 'edit_pfts_species', :partial => 'edit_pfts_species'
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

    #Different from rest to deal with "species/specie"...
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
     search_cond = [Specie.column_names.collect {|x| "species." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @species = Specie.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "species.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end



  # GET /species
  # GET /species.xml
  def index

    if params[:format].nil? or params[:format] == 'html'

#      @letter = params[:letter] ||= "A"
#
#      if @letter[/^[A-Z]$/].nil?
#        @letter = "A"
#      end
#
#      @species = Specie.by_letter(@letter).paginate :page => params[:page], :order => "genus"
      @species = Specie.paginate :page => params[:page], :order => "genus"
    else
      conditions = {}
      params.each do |k,v|
        next if !Specie.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @species = Specie.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
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
    @specie = Specie.find(params[:id])

    respond_to do |format|
      if @specie.update_attributes(params[:specie])
        flash[:notice] = 'Specie was successfully updated.'
        format.html { redirect_to( edit_species_path(@specie) ) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @specie.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @specie.errors, :status => :unprocessable_entity }
        format.json  { render :json => @specie.errors, :status => :unprocessable_entity }
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


#  def symbol_search
#    @phrase = params[:symbol]
#
#    @match = Specie.find(:first, :conditions => [ 'AcceptedSymbol like ?', @phrase ], :limit => 100)
#
#    render(:layout => false)
#  end
end
