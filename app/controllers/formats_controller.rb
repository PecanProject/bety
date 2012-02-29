class FormatsController < ApplicationController

  before_filter :login_required 

  layout 'application'
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
     search_cond = [Format.column_names.collect {|x| "formats." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @formats = Format.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "formats.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end


  # GET /formats
  # GET /formats.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @formats = Format.paginate :page => params[:page], :per_page => 20
    else
      conditions = {}
      params.each do |k,v|
        next if !Format.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @formats = Format.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
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
    @format = Format.new(params["form"])

    if !params[:mime_type_other].blank?
      @format.mime_type = params[:mime_type_other]
    end

    # Want to move recently used string to top, this will do this by adding them to end of
    # the table
    m = Mimetype.find_by_type_string(@format.mime_type)
    m.delete if !m.nil?
    Mimetype.new(:type_string => @format.mime_type).save


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
end
