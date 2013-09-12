class DbfilesController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

  require 'csv'

  def download
    file = DBFile.find(params[:id]) rescue nil

    # Need to make sure someone cannot create a link to other files on forecast
    # by modifying the file_path attribute. By recalculating the file path here
    # it should not matter if they change it in the interface it will not work.
    # 
    if file and File.exists?(File.join(DBFile.make_md5_path(file.md5),file.md5)) and !File.join(DBFile.make_md5_path(file.md5),file.md5).match(/[^A-Za-z0-9\/]/)  # On host machine, in proper path, does not match anything out the ordinary
      send_file file.file_path, :type => file.format.mime_type, :disposition => 'inline', :filename => file.file_name
    else
      redirect_to no_dbfiles_path
    end
  end

  def no
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => 'No file found' }
      format.json  { render :json => 'No file found' }
    end
  end

  def unlink
    dbfile = DBFile.find(params[:id])
    dbfile.container = nil

    respond_to do |format|
      if dbfile.save
        flash[:notice] = "File unlinked"
        format.html { redirect_to :back }
        format.xml  { render :xml => 'File unlinked' }
        format.json  { render :json => 'File unlinked' }
      else
        flash[:notice] = "File not removed"
        format.html {redirect_to :back }
        format.xml  { render :xml => 'File not removed' }
        format.json  { render :json => 'File not removed' }
      end
    end
  end
  

  # GET /files
  # GET /files.xml
  def index

    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @files = DBFile.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else
      @files = DBFile.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js 
      format.xml  { render :xml => @files }
      format.csv  { render :csv => @files }
      format.json  { render :json => @files }
    end
  end

  # GET /files/1
  # GET /files/1.xml
  def show
    @file = DBFile.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @file }
      format.csv  { render :csv => @file }
      format.json  { render :json => @file }
    end
  end

  # GET /files/new
  # GET /files/new.xml
  def new
    @file = DBFile.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /files/1/edit
  def edit
    @file = DBFile.find(params[:id])
  end

  # POST /files
  # POST /files.xml
  def create
    @file = DBFile.new
    @file.setup(current_user.id,params[:upload_file],params[:db_file])

    respond_to do |format|
      if @file.save
        flash[:notice] = 'DBFile was successfully created.'
        format.html { redirect_to dbfile_path(@file) }
        format.xml  { render :xml => @file, :status => :created, :location => @file }
        format.csv  { render :csv => @file, :status => :created, :location => @file }
        format.json  { render :json => @file, :status => :created, :location => @file }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @file.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @file.errors, :status => :unprocessable_entity }
        format.json  { render :json => @file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /files/1
  # PUT /files/1.xml
  def update
    @file = DBFile.find(params[:id])

    #params["file"].delete("user_id")

    respond_to do |format|
      if @file.update_attributes(params[:db_file])
        flash[:notice] = 'DBFile was successfully updated.'
        format.html { redirect_to(:action => :edit) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @file.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @file.errors, :status => :unprocessable_entity }
        format.json  { render :json => @file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /files/1
  # DELETE /files/1.xml
  def destroy
    @file = DBFile.find(params[:id])
    @file.destroy
    # Actual uploaded file not deleted

    respond_to do |format|
      format.html { redirect_to(dbfiles_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
