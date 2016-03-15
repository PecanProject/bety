class InputsController < ApplicationController

  before_filter :login_required
  helper_method :sort_direction, :sort_column

  # general autocompletion
  def autocomplete
    inputs = search_model(Input.joins(:site), %w( name sitename), params[:term])

    inputs = inputs.to_a.map do |item|
      {
        # show input name and site name in suggestions
        label: item.autocomplete_label,
        value: item.id
      }
    end

    respond_to do |format|
      format.json { render :json => inputs }
    end
  end

  def edit_inputs_files
    @input = Input.find(params[:id])
    file = params[:file]

    if @input and file
      _file = DBFile.find(file)
      # If relationship exists we must want to remove it...
      if @input.files.include?(_file)
        @input.files.delete(_file)
        logger.info "deleted input:#{@input.id} - file:#{_file.id}"
      # Otherwise add it
      else
        @input.files << _file
        logger.info "add input:#{@input.id} - file:#{_file.id}"
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
      search_cond = [["file_path", "file_name"].collect {|x| "dbfiles.#{x}" }.join(" LIKE :search OR ") + " LIKE :search", {:search => @search}]
      search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end

    if @input and @search.blank?
      search = "Showing already related records"
      if @input.files
        @files = @input.files.paginate :page => params[:page]
      end
    else
      @files = DBFile.paginate :select => "id,file_name", :page => params[:page], :conditions => search_cond
    end

    render :update do |page|
      page.replace_html :files_index_table, :partial => "edit_inputs_files_table"
      page.replace_html :files_search_term, search
    end
  end

  # GET /inputs
  # GET /inputs.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @inputs = Input.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page],
        :per_page => params[:DataTables_Table_0_length]
      )
      @dbfiles = DBFile.all
    else
      @inputs = Input.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @inputs }
      format.csv  { render :csv => @inputs }
      format.json  { render :json => @inputs }
    end
  end

  # GET /inputs/1
  # GET /inputs/1.xml
  def show
    @input = Input.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @input }
      format.csv  { render :csv => @input }
      format.json  { render :json => @input }
    end
  end

  # GET /inputs/new
  # GET /inputs/new.xml
  def new
    @input = Input.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @input }
      format.csv  { render :csv => @input }
      format.json  { render :json => @input }
    end
  end

  # GET /inputs/1/edit
  def edit
    @input = Input.find(params[:id])
    @files = @input.files.paginate :page => params[:page]
  end

  # POST /inputs
  # POST /inputs.xml
  def create

    @input = Input.new(params[:input])
    @input.user_id = current_user.id

    respond_to do |format|
      #if @input.save and input_file.save
      if @input.save
        format.html { redirect_to(@input, :notice => 'Input was successfully created.') }
        format.xml  { render :xml => @input, :status => :created, :location => @input }
        format.csv  { render :csv => @input, :status => :created, :location => @input }
        format.json  { render :json => @input, :status => :created, :location => @input }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @input.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @input.errors, :status => :unprocessable_entity }
        format.json  { render :json => @input.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /inputs/1
  # PUT /inputs/1.xml
  def update
    @input = Input.find(params[:id])
    if params[:dbfile_id] and !params[:dbfile_id].blank?
      dbfile = DBFile.find(params[:dbfile_id])
    end

    respond_to do |format|
      if @input.update_attributes(params[:input])
        @input.files << dbfile if dbfile
        format.html { redirect_to(@input, :notice => 'Input was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @input.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @input.errors, :status => :unprocessable_entity }
        format.json  { render :json => @input.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /inputs/1
  # DELETE /inputs/1.xml
  def destroy
    @input = Input.find(params[:id])
    @input.destroy

    respond_to do |format|
      format.html { redirect_to(inputs_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
