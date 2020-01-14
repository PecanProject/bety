class FormatsController < ApplicationController

  before_action :login_required
  helper_method :sort_column, :sort_direction

  def rem_formats_variables
    formats_variable = FormatsVariable.find(params[:id])
    @format = formats_variable.format
    formats_variable.destroy

    respond_to do |format|
      format.js {
        render "edit_formats_variables", layout: false
      }
    end
  end

  def add_formats_variables
    @format = Format.find(params[:id])
    formats_variable = FormatsVariable.new(params[:formats_variable])
    formats_variable.format = @format
    formats_variable.variable = Variable.find(params[:variable_id])
    formats_variable.save

    respond_to do |format|
      format.js {
        render "edit_formats_variables", layout: false
      }
    end
  end

  def edit_formats_variables
    formats_variable = FormatsVariable.find(params[:id])
    @format = formats_variable.format
    formats_variable.update_attributes(params[:formats_variable])

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  # GET /formats
  # GET /formats.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @formats = Format.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else
      @format = Format.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @formats }
      format.csv  { render :csv => @formats }
      format.json  { render :json => @formats }
    end
  end

  # GET /formats/1
  # GET /formats/1.xml
  def show
    @format = Format.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @format }
      format.csv  { render :csv => @format }
      format.json  { render :json => @format }
    end
  end

  # GET /formats/new
  # GET /formats/new.xml
  def new
    @format = Format.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @format }
      format.csv  { render :csv => @format }
      format.json  { render :json => @format }
    end
  end

  # GET /formats/1/edit
  def edit
    @format = Format.find(params[:id])
  end

  # POST /formats
  # POST /formats.xml
  def create

    maybe_add_mimetype(params)

    @format = Format.new(params["form"])

    respond_to do |format|
      if @format.save
        format.html { redirect_to(@format, :notice => 'Format was successfully created.') }
        format.xml  { render :xml => @format, :status => :created, :location => @format }
        format.csv  { render :csv => @format, :status => :created, :location => @format }
        format.json  { render :json => @format, :status => :created, :location => @format }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @format.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @format.errors, :status => :unprocessable_entity }
        format.json  { render :json => @format.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /formats/1
  # PUT /formats/1.xml
  def update
    @format = Format.find(params[:id])

    maybe_add_mimetype(params)

    respond_to do |format|
      if @format.update_attributes(params[:form])
        format.html { redirect_to(@format, :notice => 'Format was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @format.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @format.errors, :status => :unprocessable_entity }
        format.json  { render :json => @format.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /formats/1
  # DELETE /formats/1.xml
  def destroy
    @format = Format.find(params[:id])
    @format.destroy

    respond_to do |format|
      format.html { redirect_to(formats_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

  private

  # If params included a non-blank :mime_type_other key, try to find an existing
  # corresponding mimetype, or if not found, try to add a new mimetype using
  # that as the type string; then use its id as the value for the mimetype_id
  # attribute stored in params[:form].
  def maybe_add_mimetype(params)

    mime_type_other = params[:mime_type_other]

    if !mime_type_other.blank?

      # Check to see if it already exists before creating a new mimetype:
      m = Mimetype.find_by_type_string(mime_type_other)
      if m.nil?
        m = Mimetype.new(type_string: mime_type_other)
        if m.valid?
          m.save
        end
      end

      params[:form][:mimetype_id] = m.id
    end
  end

end
