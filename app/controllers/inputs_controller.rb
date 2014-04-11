class InputsController < ApplicationController

  before_filter :login_required 
  helper_method :sort_direction, :sort_column

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
