class InputsController < ApplicationController

  before_filter :login_required 

  layout 'application'

  def rem_inputs_runs
    @input = Input.find(params[:input_id])
    @run = Run.find(params[:run_id])

    render :update do |page|
      @input.runs.delete(@run)
      page.replace_html 'edit_inputs_runs', :partial => 'edit_inputs_runs'
    end
  end

  def edit_inputs_runs

    @input = Input.find(params[:input_id])

    render :update do |page|
      if !params[:run].nil?
        params[:run][:id].each do |run|
          @input.runs << Run.find(run)
        end
      end
      page.replace_html 'edit_inputs_runs', :partial => 'edit_inputs_runs'
    end
  end

  def rem_inputs_variables
    @input = Input.find(params[:input_id])
    @variable = Variable.find(params[:variable_id])

    render :update do |page|
      @input.variables.delete(@variable)
      page.replace_html 'edit_inputs_variables', :partial => 'edit_inputs_variables'
    end
  end

  def edit_inputs_variables

    @input = Input.find(params[:input_id])

    render :update do |page|
      if !params[:variable].nil?
        params[:variable][:id].each do |variable|
          @input.variables << Variable.find(variable)
        end
      end
      page.replace_html 'edit_inputs_variables', :partial => 'edit_inputs_variables'
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
     search_cond = [Input.column_names.collect {|x| "inputs." + x }.join(" like :search or ") + " like :search", {:search => @search}] 
     search_cond[0] += " or " + Site.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Variable.search_columns.join(" like :search or ") + " like :search"
     search_cond[0] += " or " + Format.search_columns.join(" like :search or ") + " like :search"
     search = "Showing records for \"#{@search}\""
    else
      @search = ""
      search = "Showing all results"
      search_cond = ""
    end
    
    @inputs = Input.paginate :order => @current_sort+$sort_table[@current_sort_order],
                             :page => params[:page],
                             :include => [:site,:variables,:format],
                             :conditions => search_cond 

    render :update do |page|
      page.replace_html :index_table, :partial => "index_table"
      page.assign "current_sort", @current_sort
      page.assign "current_sort_order", @current_sort_order
      page.replace_html :search_term, search
      if @current_sort != "inputs.id"
        if @current_sort_order 
          page.replace_html "#{@current_sort}",  image_tag("up_arrow.gif")
        else
          page.replace_html "#{@current_sort}",  image_tag("down_arrow.gif")
        end
      end
    end
  end



  # GET /inputs
  # GET /inputs.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @inputs = Input.paginate :page => params[:page], :per_page => 20
    else
      conditions = {}
      params.each do |k,v|
        next if !Input.column_names.include?(k)
        conditions[k] = v
      end
      logger.info conditions.to_yaml
      @inputs = Input.all(:conditions => conditions)
    end

    respond_to do |format|
      format.html # index.html.erb
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
  end

  # POST /inputs
  # POST /inputs.xml
  def create

    new_file = params.delete(:file)

    @input = Input.new(params[:input])

    input_file = InputFile.new
    input.save
    

    respond_to do |format|
      if  @input.format.save and @input.format_id = @input.format.id and @input.save
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

    respond_to do |format|
      if @input.update_attributes(params[:input])
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
