class ManagementsController < ApplicationController
  before_filter :login_required

  layout 'application'

  require 'csv'

  def rem_managements_treatments
    @management = Management.find(params[:id])
    @treatment = Treatment.find(params[:treatment])

    render :update do |page|
      if @management.treatments.delete(@treatment)
        page.replace_html 'edit_managements_treatments', :partial => 'edit_managements_treatments'
      else
        page.replace_html 'edit_managements_treatments', :partial => 'edit_managements_treatments'
      end
    end
  end

  def edit_managements_treatments

    @management = Management.find(params[:id])

    render :update do |page|
      if !params[:treatment].nil?
        params[:treatment][:id].each do |c|
          @management.treatments << Treatment.find(c)
        end
        page.replace_html 'edit_managements_treatments', :partial => 'edit_managements_treatments'
      else
        page.replace_html 'edit_managements_treatments', :partial => 'edit_managements_treatments'
      end
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
     search_cond = [Management.column_names.collect {|x| "managements." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search_cond[0] += " or " + Citation.search_columns.join(" like :search or ") + " like :search"
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @managements = Management.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :per_page => 20, :include => [:citation], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "managements.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end


  # GET /managements
  # GET /managements.xml
  def index
    #@managements = Management.find(:all, :limit => 100)
    if params[:format].nil? or params[:format] == 'html'
      @managements = Management.paginate :page => params[:page], :per_page => 20
    else
      conditions = {}
      params.each do |k,v|
        next if !Management.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @managements = Management.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @managements }
      format.csv  { render :csv => @managements }
      format.json  { render :json => @managements }
    end
  end

  # GET /managements/1
  # GET /managements/1.xml
  def show
    @management = Management.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @management }
      format.csv  { render :csv => @management }
      format.json  { render :json => @management }
    end
  end

  # GET /managements/new
  # GET /managements/new.xml
  def new

    @management = Management.new

    respond_to do |format|
      if !params[:treatment].nil?
        @treatment = params[:treatment]
        format.html # new.html.erb
        format.xml  { render :xml => @management }
        format.csv  { render :csv => @management }
        format.json  { render :json => @management }
      else
        format.html { redirect_to treatments_path }
      end
    end
  end

  # GET /managements/1/edit
  def edit
    @management = Management.find(params[:id])
  end

  # POST /managements
  # POST /managements.xml
  def create
    @management = Management.new(params[:management])
    @management.citation = Citation.find(session["citation"]) if !session["citation"].nil?
    
    # they should only add management when they have a citation selected
    # and they came via the 'new' link on the treatments page which
    # will provide a treatment_id, if not we should not create it
        
    problem = true if params[:treatment].empty? or session["citation"].nil?

    @management.user = current_user

    respond_to do |format|
      if (( !problem ) or !params[:format].nil?) and @management.save
        @management.treatments << Treatment.find(params[:treatment])
        flash[:notice] = 'Management was successfully created.'
        format.html { redirect_to( treatments_path ) }
        format.xml  { render :xml => @management, :status => :created, :location => @management }
        format.csv  { render :csv => @management, :status => :created, :location => @management }
        format.json  { render :json => @management, :status => :created, :location => @management }
      else
        flash[:notice] = 'Management was not created.'
        format.html { redirect_to( treatments_path ) }
        format.xml  { render :xml => @management.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @management.errors, :status => :unprocessable_entity }
        format.json  { render :json => @management.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /managements/1
  # PUT /managements/1.xml
  def update
    @management = Management.find(params[:id])

    params[:management].delete("user_id")

    respond_to do |format|
      if @management.update_attributes(params[:management])
        @management.update_attribute('citation_id', session['citation'])
        flash[:notice] = 'Management was successfully updated.'
        format.html { redirect_to( :action => :edit ) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @management.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @management.errors, :status => :unprocessable_entity }
        format.json  { render :json => @management.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /managements/1
  # DELETE /managements/1.xml
  def destroy
    @management = Management.find(params[:id])
    @management.treatments.destroy
    @management.destroy

    respond_to do |format|
      format.html { redirect_to(managements_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end
end
