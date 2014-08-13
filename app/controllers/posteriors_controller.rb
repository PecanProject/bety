class PosteriorsController < ApplicationController

  before_filter :login_required 
  helper_method :sort_column, :sort_direction

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
