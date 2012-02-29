class RawsController < ApplicationController

  before_filter :login_required 
  before_filter :access_conditions

  layout 'application'

  def download
    raw = RawsDocument.find(params[:document_id])
    send_file( raw.doc.path, :type => raw.doc_content_type, :disposition => 'inline' )
  end

 def search
    sort = params[:sort]

    @page = params[:page]
    @current_sort = params[:current_sort]
    params[:current_sort_order].match(/true/) ? @current_sort_order = true : @current_sort_order = false

    @search = params[:search]
    # If they search just a number it is probably an id, and we do not want to wrap that in wildcards.
    @search.match(/\D/) ? wildcards = true : wildcards = false

    if sort and sort.split(".")[0].classify.constantize.column_names.include?(sort.split(".")[1])
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
     search_cond = [Raw.column_names.collect {|x| "raws." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search_cond[0] += " or " + Site.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Format.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Ensemble.search_columns.join(" like :search or ") + " like :search"
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @raws = Raw.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :include => [:site, :format, :ensemble], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "raws.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end


  # GET /raws
  # GET /raws.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @raws = Raw.all_limited($access_level).paginate :page => params[:page], :per_page => 20
    else
      conditions = {}
      params.each do |k,v|
        next if !Raw.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @raws = Raw.all_limited($access_level).all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @raws }
      format.csv  { render :csv => @raws }
      format.json  { render :json => @raws }
    end
  end

  # GET /raws/1
  # GET /raws/1.xml
  def show
    @raw = Raw.all_limited($access_level).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @raw }
      format.csv  { render :csv => @raw }
      format.json  { render :json => @raw }
    end
  end

  # GET /raws/new
  # GET /raws/new.xml
  def new
    @raw = Raw.new
    @raw.raws_documents.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @raw }
      format.csv  { render :csv => @raw }
      format.json  { render :json => @raw }
    end
  end

  # GET /raws/1/edit
  def edit
    @raw = Raw.all_limited($access_level).find(params[:id])
    @raw.raws_documents.build

  end

  # POST /raws
  # POST /raws.xml
  def create
    @raw = Raw.new(params[:raw])
    @raw.user = current_user

    @raw.filepath_override = false

#    if params[:raw][:data]
#      #Allows us to use the MD5 sum in the filename
#      #Will not need to do this when we can update Paperclip
#      @raw.md5 = Digest::MD5.file(params[:raw][:data].path).hexdigest
#    end

    respond_to do |format|
      if @raw.save
        @raw.update_attribute(:filepath, @raw.raws_documents.all(:order => "id desc").first.doc.path) if @raw.raws_documents.all(:order => "id desc").first
        format.html { redirect_to(@raw, :notice => 'Raw was successfully created.') }
        format.xml  { render :xml => @raw, :status => :created, :location => @raw }
        format.csv  { render :csv => @raw, :status => :created, :location => @raw }
        format.json  { render :json => @raw, :status => :created, :location => @raw }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @raw.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @raw.errors, :status => :unprocessable_entity }
        format.json  { render :json => @raw.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /raws/1
  # PUT /raws/1.xml
  def update
    @raw = Raw.all_limited($access_level).find(params[:id])

    params[:raw].delete(:filepath) if current_user.page_access_level > 2

#    if params[:raw][:data]
#      #Allows us to use the MD5 sum in the filename
#      #Will not need to do this when we can update Paperclip
#      params[:raw][:md5] = Digest::MD5.file(params[:raw][:data].path).hexdigest
#    end

    respond_to do |format|
      if @raw.update_attributes(params[:raw])
        #Set the file name to the last uploaded file...
        @raw.update_attribute(:filepath, @raw.raws_documents.all(:order => "id desc").first.doc.path) if @raw.raws_documents.all(:order => "id desc").first and !@raw.filepath_override
        format.html { redirect_to(@raw, :notice => 'Raw was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @raw.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @raw.errors, :status => :unprocessable_entity }
        format.json  { render :json => @raw.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /raws/1
  # DELETE /raws/1.xml
  def destroy
    @raw = Raw.all_limited($access_level).find(params[:id])
    @raw.destroy

    respond_to do |format|
      format.html { redirect_to(raws_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end
end
