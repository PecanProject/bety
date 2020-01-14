class PriorsController < ApplicationController
  before_action :login_required
  helper_method :sort_column, :sort_direction

  require 'csv'
  require 'open3'

  def search_pfts
    @prior = Prior.find(params[:id])

    # the "sorted_order" call is mainly so "search" has the joins it needs
    @pfts = Pft.sorted_order("#{sort_column('pfts','updated_at')} #{sort_direction}").search(params[:search_pfts])

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  def rem_pfts_priors
    @prior = Prior.find(params[:id])
    @pft = Pft.find(params[:pft])

    @prior.pfts.delete(@pft)

    respond_to do |format|
      format.js {
        render layout: false
      }
    end
  end

  def add_pfts_priors
    @prior = Prior.find(params[:id])
    @pft = Pft.find(params[:pft])

    @prior.pfts << @pft

    respond_to do |format|
      format.js {
        render layout: false
      }
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
    imgfile = Rails.root.join("public/images/prev/#{id}.png").to_s
    updatetime = @prior.updated_at

    if updatetime.nil?
      updatetime = Time.at(0)
    end

    if !File.exist?( imgfile ) or File.atime(imgfile) < updatetime

      if id =~ /\A\d+\z/ &&
          Prior.distn_types.include?(distname) &&
          aparam.is_a?(Numeric) &&
          (n.nil? || bparam.is_a?(Numeric)) &&
          (n.nil? || n.is_a?(Integer))

        # On ebi-forecast, the version of R we want to use is in
        # /usr/local/R-3.1.0/bin, so put it first in the path so that that version
        # gets used if it exists:
        path_additions = "/usr/local/R-3.1.0/bin:"

        o, error_output, s = Open3.capture3(
                           {"PATH" => path_additions + ENV["PATH"]},
                           "R", "--vanilla", "--args", imgfile, distname,
                           aparam.to_s, bparam.to_s, n.to_s,
                           stdin_data: Rails.root.join('script/previewhelp.R').read
                         )

      else
        error_output = sprintf("Invalid argument set:\n\timgfile = %s\n\tdistname = %s\n\taparam = %s\n\tbparam = %s\n\tn = %s\n", 
                               imgfile, distname, aparam, bparam, n)
      end

      if !error_output.empty?
        logger.error("\nR error output:")
        logger.error("========================================")
        logger.error(error_output)
        logger.error("========================================\n\n")
      end
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
    @pfts = @prior.pfts

    respond_to do |format|
      format.html
      format.js {

        render layout: false
      }
    end
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
        format.html { @pfts = @prior.pfts
                      render :action => "edit" }
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
    @prior.destroy

    respond_to do |format|
      format.html { redirect_to(priors_url) }
      format.xml  { head :ok }
      format.csv  { head :ok }
      format.json  { head :ok }
    end
  end

end
