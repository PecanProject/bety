class ModelsController < ApplicationController

  before_action :login_required
  helper_method :sort_column, :sort_direction

  def edit_models_files
    @model = Model.find(params[:id])
    file = params[:file]

    if @model and file
      _file = DBFile.find(file)
      # If relationship exists we must want to remove it...
      if @model.files.include?(_file)
        @model.files.delete(_file)
        logger.info "deleted model:#{@model.id} - file:#{_file.id}"
      # Otherwise add it
      else
        @model.files << _file
        logger.info "add model:#{@model.id} - file:#{_file.id}"
      end
    end

    @page = params[:page]

    # RAILS3 had to add the || '' in order for @search not be nil when params[:search] is nil
    @search = params[:search] || ''
    @searchparam = @search

    # If they search just a number it is probably an id, and we do not want to wrap that in wildcards.
    # @search.match(/\D/) ? wildcards = true : wildcards = false
    # We now ALWAYS use wildcards (unless the search is blank).
    wildcards = true

    if !@search.blank? 
      if wildcards 
        @search = "%#{@search}%"
      end
      search_cond = ["container_id IS NULL AND (file_path LIKE :search OR file_name LIKE :search)", {:search => @search}] 
      search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end

    if @model and @search.blank?
      search = "Showing already related records"
      if @model.files
        @files = @model.files.paginate :page => params[:page]
      end
    else
      @files = DBFile.where(search_cond).select("id,file_name").page(params[:page])
    end


    respond_to do |format|
      format.js {
        render layout: false, locals: { search: search }
      }
    end
  end

  # GET /models
  # GET /models.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @models = Model.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @models = Model.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @models }
      format.csv  { render :csv => @models }
      format.json  { render :json => @models }
    end
  end

  # GET /models/1
  # GET /models/1.xml
  def show
    @model = Model.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @model }
      format.csv  { render :csv => @model }
      format.json  { render :json => @model }
    end
  end

  # GET /models/new
  # GET /models/new.xml
  def new
    @model = Model.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @model }
      format.csv  { render :csv => @model }
      format.json  { render :json => @model }
    end
  end

  # GET /models/1/edit
  def edit
    @model = Model.find(params[:id])
    @files = @model.files.paginate :page => params[:page]
  end

  # POST /models
  # POST /models.xml
  def create
    @model = Model.new(params[:model])

    respond_to do |format|
      if @model.save
        format.html { redirect_to(@model, :notice => 'Model was successfully created.') }
        format.xml  { render :xml => @model, :status => :created, :location => @model }
        format.csv  { render :csv => @model, :status => :created, :location => @model }
        format.json  { render :json => @model, :status => :created, :location => @model }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @model.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @model.errors, :status => :unprocessable_entity }
        format.json  { render :json => @model.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /models/1
  # PUT /models/1.xml
  def update
    @model = Model.find(params[:id])

    respond_to do |format|
      if @model.update_attributes(params[:model])
        format.html { redirect_to(@model, :notice => 'Model was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { @files = @model.files.paginate :page => params[:page]; render :action => "edit" }
        format.xml  { render :xml => @model.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @model.errors, :status => :unprocessable_entity }
        format.json  { render :json => @model.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /models/1
  # DELETE /models/1.xml
  def destroy
    @model = Model.find(params[:id])
    @model.destroy

    respond_to do |format|
      format.html { redirect_to(models_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
