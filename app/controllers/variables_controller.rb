class VariablesController < ApplicationController
  before_filter :login_required

  layout 'application'

  require 'csv'

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
     search_cond = [Variable.column_names.collect {|x| "variables." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @variables = Variable.paginate :order => @current_sort+$sort_table[@current_sort_order], :page => params[:page], :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "variables.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end



  # GET /variables
  # GET /variables.xml
  def index
    #@variables = Variable.all
    if params[:format].nil? or params[:format] == 'html'
      @variables = Variable.paginate :page => params[:page], :order => 'name'
    else
      conditions = {}
      params.each do |k,v|
        next if !Variable.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @variables = Variable.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @variables }
      format.csv  { render :csv => @variables }
      format.json  { render :json => @variables }
    end
  end

  # GET /variables/1
  # GET /variables/1.xml
  def show
    @variable = Variable.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @variable }
      format.csv  { render :csv => @variable }
      format.json  { render :json => @variable }
    end
  end

  # GET /variables/new
  # GET /variables/new.xml
  def new
    @variable = Variable.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @variable }
      format.csv  { render :csv => @variable }
      format.json  { render :json => @variable }
    end
  end

  # GET /variables/1/edit
  def edit
    @variable = Variable.find(params[:id])
  end

  # POST /variables
  # POST /variables.xml
  def create
    @variable = Variable.new(params[:variable])

    respond_to do |format|
      if @variable.save
        flash[:notice] = 'Variable was successfully created.'
        format.html { redirect_to( edit_variable_path(@variable) ) }
        format.xml  { render :xml => @variable, :status => :created, :location => @variable }
        format.csv  { render :csv => @variable, :status => :created, :location => @variable }
        format.json  { render :json => @variable, :status => :created, :location => @variable }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @variable.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @variable.errors, :status => :unprocessable_entity }
        format.json  { render :json => @variable.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /variables/1
  # PUT /variables/1.xml
  def update
    @variable = Variable.find(params[:id])

    respond_to do |format|
      if @variable.update_attributes(params[:variable])
        flash[:notice] = 'Variable was successfully updated.'
        format.html { redirect_to(@variable) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @variable.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @variable.errors, :status => :unprocessable_entity }
        format.json  { render :json => @variable.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /variables/1
  # DELETE /variables/1.xml
  def destroy
    @variable = Variable.find(params[:id])
    @variable.traits.destroy
    @variable.destroy

    respond_to do |format|
      format.html { redirect_to(variables_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

#  def search
#    @phrase = params[:symbol]
#
#    @match = Variable.find(:all, :conditions => [ 'description like ? or name like ? or id = ?', @phrase, @phrase, @phrase ], :limit => 100)
#
#    render(:layout => false)
#  end

#  def csv_import 
#    @parsed_file=CSV::Reader.parse(params[:dump][:file])
#    n=0
#
#    errors = Hash.new
#
#    @parsed_file.each  do |row|
#      error = ""
#      c=Variable.new
#      c.name=row[0] or error += "Name, " 
#      c.description=row[1] or error += "Description, "
#      c.units=row[2] or error += "Units, "
#      c.notes=row[3] or error += "Notes "
#      if c.save
#        if !error.empty?
#          @error = Error_log.new
#          @error.record_id = c.id
#          @error.description = error
#          @error.type = "Variable"
#          @error.save
#          errors << c.id
#        end
#        n=n+1
#        GC.start if n%50==0
#      end
#    end
#    flash[:notice]="CSV Import Successful,  #{n} new records added"
#
#    if errors.empty? 
#      redirect_to :action => "index"
#    else
#      redirect_to :action => "csv_missing", :errors => errors
#    end
#  end

  #produce a list of list of csv import file missing info
#  def csv_missing
#    @variables = Variable.find(:all, :conditions => ["id in (?)", params[:errors].keys ])
#    @errors = params[:errors]
#
#    respond_to do |format|
#      format.html 
#      format.xml  { render :xml => @variables }
#    end
#  end

#  def rem_traits_variables
#    @variable = Variable.find(params[:id])
#    @trait = Trait.find(params[:trait])
#
#    render :update do |page|
#      if @variable.traits.delete(@trait)
#        page.replace_html 'edit_traits_variables', :partial => 'edit_traits_variables'
#      else
#        page.replace_html 'edit_traits_variables', :partial => 'edit_traits_variables'
#      end
#    end
#  end

#  def edit_traits_variables
#
#    @variable = Variable.find(params[:id])
#
#    render :update do |page|
#      if !params[:trait].nil?
#        params[:trait][:id].each do |c|
#          @variable.traits << Trait.find(c)
#        end
#        page.replace_html 'edit_traits_variables', :partial => 'edit_traits_variables'
#      else
#        page.replace_html 'edit_traits_variables', :partial => 'edit_traits_variables'
#      end
#    end
#  end


end
