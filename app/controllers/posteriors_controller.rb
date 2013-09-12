class PosteriorsController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

  def rem_posteriors_runs
    @posterior = Posterior.find(params[:id])
    @run = Run.find(params[:run_id])

    render :update do |page|
      @posterior.runs.delete(@run)
      page.replace_html 'edit_posteriors_runs', :partial => 'edit_posteriors_runs'
    end
  end

  def edit_posteriors_runs

    @posterior = Posterior.find(params[:posterior_id])

    render :update do |page|
      if !params[:run].nil?
        params[:run][:id].each do |run|
          @posterior.runs << Run.find(run)
        end
      end
      page.replace_html 'edit_posteriors_runs', :partial => 'edit_posteriors_runs'
    end
  end

  # GET /posteriors
  # GET /posteriors.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @posteriors = Posterior.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @posteriors = Posterior.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @posteriors }
      format.csv  { render :csv => @posteriors }
      format.json  { render :json => @posteriors }
    end
  end

  # GET /posteriors/1
  # GET /posteriors/1.xml
  def show
    @posterior = Posterior.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @posterior }
      format.csv  { render :csv => @posterior }
      format.json  { render :json => @posterior }
    end
  end

  # GET /posteriors/new
  # GET /posteriors/new.xml
  def new
    @posterior = Posterior.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @posterior }
      format.csv  { render :csv => @posterior }
      format.json  { render :json => @posterior }
    end
  end

  # GET /posteriors/1/edit
  def edit
    @posterior = Posterior.find(params[:id])
  end

  # POST /posteriors
  # POST /posteriors.xml
  def create
    @posterior = Posterior.new(params[:posterior])

    respond_to do |format|
      if @posterior.save
        format.html { redirect_to(@posterior, :notice => 'Posterior was successfully created.') }
        format.xml  { render :xml => @posterior, :status => :created, :location => @posterior }
        format.csv  { render :csv => @posterior, :status => :created, :location => @posterior }
        format.json  { render :json => @posterior, :status => :created, :location => @posterior }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @posterior.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @posterior.errors, :status => :unprocessable_entity }
        format.json  { render :json => @posterior.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /posteriors/1
  # PUT /posteriors/1.xml
  def update
    @posterior = Posterior.find(params[:id])

    respond_to do |format|
      if @posterior.update_attributes(params[:posterior])
        format.html { redirect_to(@posterior, :notice => 'Posterior was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @posterior.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @posterior.errors, :status => :unprocessable_entity }
        format.json  { render :json => @posterior.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /posteriors/1
  # DELETE /posteriors/1.xml
  def destroy
    @posterior = Posterior.find(params[:id])
    @posterior.destroy

    respond_to do |format|
      format.html { redirect_to(posteriors_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
