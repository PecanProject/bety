class ModeltypesController < ApplicationController

  before_action :login_required
  helper_method :sort_column, :sort_direction

  def remove_modeltypes_format
    @modeltypes_format = ModeltypesFormat.find(params[:id])
    @modeltype = @modeltypes_format.modeltype

    @modeltypes_format.destroy

    respond_to do |format|
      format.js {
        render "edit_modeltypes_format", layout: false
      }
    end
  end

  def add_modeltypes_format
    @modeltype = Modeltype.find(params[:id])
    @modeltypes_format = ModeltypesFormat.new(params[:modeltypes_format])
    @modeltypes_format.modeltype = @modeltype
    @modeltypes_format.format = Format.find(params[:format_id])
    @modeltypes_format.save

    respond_to do |format|
      format.js {
        render "edit_modeltypes_format", layout: false
      }
    end
  end

  def edit_modeltypes_format
    @modeltypes_format = ModeltypesFormat.find(params[:id])
    @modeltype = @modeltypes_format.modeltype
    @modeltypes_format.update_attributes(params[:modeltypes_format])

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  # GET /modeltypes
  # GET /modeltypes.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @modeltypes = Modeltype.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @modeltypes = Modeltype.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @modeltypes }
      format.csv  { render :csv => @modeltypes }
      format.json  { render :json => @modeltypes }
    end
  end

  # GET /modeltypes/1
  # GET /modeltypes/1.xml
  def show
    @modeltype = Modeltype.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @modeltype }
      format.csv  { render :csv => @modeltype }
      format.json  { render :json => @modeltype }
    end
  end

  # GET /modeltypes/new
  # GET /modeltypes/new.xml
  def new
    @modeltype = Modeltype.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @modeltype }
      format.csv  { render :csv => @modeltype }
      format.json  { render :json => @modeltype }
    end
  end

  # GET /modeltypes/1/edit
  def edit
    @modeltype = Modeltype.find(params[:id])
    @models = @modeltype.models.paginate :page => params[:modelpage]
    @pfts = @modeltype.pfts.paginate :page => params[:pftpage]
  end

  # POST /modeltypes
  # POST /modeltypes.xml
  def create
    @modeltype = Modeltype.new(params[:modeltype])
    @modeltype.user = current_user

    respond_to do |format|
      if @modeltype.save
        format.html { redirect_to(@modeltype, :notice => 'Modeltype was successfully created.') }
        format.xml  { render :xml => @modeltype, :status => :created, :location => @modeltype }
        format.csv  { render :csv => @modeltype, :status => :created, :location => @modeltype }
        format.json  { render :json => @modeltype, :status => :created, :location => @modeltype }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @modeltype.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @modeltype.errors, :status => :unprocessable_entity }
        format.json  { render :json => @modeltype.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /modeltypes/1
  # PUT /modeltypes/1.xml
  def update
    @modeltype = Modeltype.find(params[:id])
    @modeltype.user = current_user

    respond_to do |format|
      if @modeltype.update_attributes(params[:modeltype])
        format.html { redirect_to(@modeltype, :notice => 'Modeltype was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @modeltype.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @modeltype.errors, :status => :unprocessable_entity }
        format.json  { render :json => @modeltype.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /modeltypes/1
  # DELETE /modeltypes/1.xml
  def destroy
    @modeltype = Modeltype.find(params[:id])
    @modeltype.destroy

    respond_to do |format|
      format.html { redirect_to(modeltypes_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
