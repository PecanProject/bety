class LikelihoodsController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

  # GET /likelihoods
  # GET /likelihoods.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @likelihoods = Likelihood.sorted_order("#{sort_column} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @likelihoods = Likelihood.api_search(params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @likelihoods }
      format.csv  { render :csv => @likelihoods }
      format.json  { render :json => @likelihoods }
    end
  end

  # GET /likelihoods/1
  # GET /likelihoods/1.xml
  def show
    @likelihood = Likelihood.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @likelihood }
      format.csv  { render :csv => @likelihood }
      format.json  { render :json => @likelihood }
    end
  end

  # GET /likelihoods/new
  # GET /likelihoods/new.xml
  def new
    @likelihood = Likelihood.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @likelihood }
      format.csv  { render :csv => @likelihood }
      format.json  { render :json => @likelihood }
    end
  end

  # GET /likelihoods/1/edit
  def edit
    @likelihood = Likelihood.find(params[:id])
  end

  # POST /likelihoods
  # POST /likelihoods.xml
  def create
    @likelihood = Likelihood.new(params[:likelihood])

    respond_to do |format|
      if @likelihood.save
        format.html { redirect_to(@likelihood, :notice => 'Likelihood was successfully created.') }
        format.xml  { render :xml => @likelihood, :status => :created, :location => @likelihood }
        format.csv  { render :csv => @likelihood, :status => :created, :location => @likelihood }
        format.json  { render :json => @likelihood, :status => :created, :location => @likelihood }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @likelihood.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @likelihood.errors, :status => :unprocessable_entity }
        format.json  { render :json => @likelihood.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /likelihoods/1
  # PUT /likelihoods/1.xml
  def update
    @likelihood = Likelihood.find(params[:id])

    respond_to do |format|
      if @likelihood.update_attributes(params[:likelihood])
        format.html { redirect_to(@likelihood, :notice => 'Likelihood was successfully updated.') }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @likelihood.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @likelihood.errors, :status => :unprocessable_entity }
        format.json  { render :json => @likelihood.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /likelihoods/1
  # DELETE /likelihoods/1.xml
  def destroy
    @likelihood = Likelihood.find(params[:id])
    @likelihood.destroy

    respond_to do |format|
      format.html { redirect_to(likelihoods_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
