class MethodsController < ApplicationController

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

    if sort and ((sort.match(/methods/) and Methods.column_names.include?(sort.split(".")[1])) or sort.split(".")[0].classify.constantize.column_names.include?(sort.split(".")[1]))
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
     search_cond = [Methods.column_names.collect {|x| "methods." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search_cond[0] += " or " + Citation.search_columns.join(" like :search or ") + " like :search"
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @methods = Methods.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :include => [:citation], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "methods.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end

  # GET /methods
  # GET /methods.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @methods = Methods.paginate :page => params[:page], :per_page => 10, :order => "name"
    else
      conditions = {}
      params.each do |k,v|
        next if !Methods.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @methods = Methods.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @methods }
    end
  end

  # GET /methods/1
  # GET /methods/1.xml
  def show
    @method = Methods.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @method }
    end
  end

  # GET /methods/new
  # GET /methods/new.xml
  def new
    @method = Methods.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @method }
    end
  end

  # GET /methods/1/edit
  def edit
    @method = Methods.find(params[:id])
  end

  # POST /methods
  # POST /methods.xml
  def create
    @method = Methods.new(params[:methods])

    respond_to do |format|
      if @method.save
        format.html { redirect_to(@method, :notice => 'Method was successfully created.') }
        format.xml  { render :xml => @method, :status => :created, :location => @method }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @method.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /methods/1
  # PUT /methods/1.xml
  def update
    @method = Methods.find(params[:id])

    respond_to do |format|
      if @method.update_attributes(params[:methods])
        format.html { redirect_to(@method, :notice => 'Method was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @method.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /methods/1
  # DELETE /methods/1.xml
  def destroy
    @method = Methods.find(params[:id])
    @method.destroy

    respond_to do |format|
      format.html { redirect_to(methods_url) }
      format.xml  { head :ok }
    end
  end
end
