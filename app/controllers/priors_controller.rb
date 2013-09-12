class PriorsController < ApplicationController
  before_filter :login_required
  helper_method :sort_column, :sort_direction

  require 'csv'

  def rem_pfts_priors
    @pft = Pft.find(params[:id])
    @prior = Prior.find(params[:prior])

    render :update do |page|
      @pft.priors.delete(@prior)
      page.replace_html 'edit_pfts_priors', :partial => 'edit_pfts_priors'
    end
  end

  def edit_pfts_priors

    @prior = Prior.find(params[:id])

    render :update do |page|
      if !params[:pft].nil?
        params[:pft][:id].each do |c|
          @prior.pfts << Pft.find(c)
        end
      end
      page.replace_html 'edit_pfts_priors', :partial => 'edit_pfts_priors'
    end
  end

  # GET /priors
  # GET /priors.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @priors = Prior.sorted_order("#{sort_column('priors','updated_at')} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(Prior)
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @priors = Prior.api_search(params)
      log_searches(Prior.method(:api_search), params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @priors }
      format.csv  { render :csv => @priors }
      format.json  { render :json => @priors }
    end
  end

  # GET /priors/1
  # GET /priors/1.xml
  def show
    @prior = Prior.find(params[:id])
    @id = params[:id]
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @prior }
      format.csv  { render :csv => @prior }
      format.json  { render :json => @prior }
    end
  end

  # GET /priors/1/preview
  def preview
    id = params[:id]
    @prior = Prior.find(id)
    aparam = @prior.parama
    bparam = @prior.paramb
    distname = @prior.distn
    n = @prior.n
    imgfile = `pwd`.strip + "/public/images/prev/#{id}.png"
    updatetime = @prior.updated_at

    if updatetime.nil?
      updatetime = Time.at(0)
    end

    if !File.exist?( imgfile ) or File.atime(imgfile) < updatetime
      system("R --vanilla --args #{imgfile} #{distname} #{aparam} #{bparam} #{n} <script/previewhelp.R")
      send_file(imgfile, :type =>'image/png', :disposition => 'inline')
    else
      send_file(imgfile, :type =>'image/png', :disposition => 'inline')
    end

  end

  # GET /priors/new
  # GET /priors/new.xml
  def new
    @prior = Prior.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @prior }
      format.csv  { render :csv => @prior }
      format.json  { render :json => @prior }
    end
  end

  # GET /priors/1/edit
  def edit
    @prior = Prior.find(params[:id])
  end

  # POST /priors
  # POST /priors.xml
  def create
    @prior = Prior.new(params[:prior])

    respond_to do |format|
      if @prior.save
        flash[:notice] = 'Prior was successfully created.'
        format.html { redirect_to( edit_prior_path(@prior) ) }
        format.xml  { render :xml => @prior, :status => :created, :location => @prior }
        format.csv  { render :csv => @prior, :status => :created, :location => @prior }
        format.json  { render :json => @prior, :status => :created, :location => @prior }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @prior.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @prior.errors, :status => :unprocessable_entity }
        format.json  { render :json => @prior.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /priors/1
  # PUT /priors/1.xml
  def update
    @prior = Prior.find(params[:id])

    respond_to do |format|
      if @prior.update_attributes(params[:prior])
        flash[:notice] = 'Prior was successfully updated.'
        format.html { redirect_to( edit_prior_path(@prior)) }
        format.xml  { head :ok }
        format.csv  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @prior.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => @prior.errors, :status => :unprocessable_entity }
        format.json  { render :json => @prior.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /priors/1
  # DELETE /priors/1.xml
  def destroy
    @prior = Prior.find(params[:id])
    @prior.pfts.destroy
    @prior.destroy

    respond_to do |format|
      format.html { redirect_to(priors_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
