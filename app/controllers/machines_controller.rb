class MachinesController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

  # GET /machines
  # GET /machines.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @machines = Machine.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else
      @machines = Machine.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @machines }
      format.json { render :json => @machines }
    end
  end

  # GET /machines/1
  # GET /machines/1.xml
  def show
    @machine = Machine.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @machine }
    end
  end

  # GET /machines/new
  # GET /machines/new.xml
  def new
    @machine = Machine.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @machine }
    end
  end

  # GET /machines/1/edit
  def edit
    @machine = Machine.find(params[:id])
  end

  # POST /machines
  # POST /machines.xml
  def create
    @machine = Machine.new(params[:machine])

    respond_to do |format|
      if @machine.save
        format.html { redirect_to(@machine, :notice => 'Machine was successfully created.') }
        format.xml  { render :xml => @machine, :status => :created, :location => @machine }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @machine.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /machines/1
  # PUT /machines/1.xml
  def update
    @machine = Machine.find(params[:id])

    respond_to do |format|
      if @machine.update_attributes(params[:machine])
        format.html { redirect_to(@machine, :notice => 'Machine was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @machine.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /machines/1
  # DELETE /machines/1.xml
  def destroy
    @machine = Machine.find(params[:id])
    @machine.destroy

    respond_to do |format|
      format.html { redirect_to(machines_url) }
      format.xml  { head :ok }
    end
  end

end
