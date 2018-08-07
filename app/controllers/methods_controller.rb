# coding: utf-8
class MethodsController < ApplicationController

  before_action :login_required
  helper_method :sort_column, :sort_direction

  # This action acts as a _source_ for the jQuery UI autocompletion widgets on
  # the Bulk Upload "Specify Upload Options and Global Values" page.  It
  # responds by sending a JSON string representing an Array of Hashes—one Hash
  # for each row of the `methods` table such that the `name` column contains the
  # text of the `:term` parameter.  (The value of the `:term` parameter is
  # automatically set by the autocompletion widget to be the text of the search
  # field.)  The matching is case-insensitive.  For each such row, the
  # corresponding Hash will have keys `:label` and `:value` with values matching
  # `methods.name` and `methods.id`, respectively.  In the special case that
  # `:term` has length 0 or 1 and no matching rows are found, the returned Array
  # will contain a Hash for each row of the table.  A special Hash `{ label:
  # "[no value]", value: nil }` will always be prepended to the Array.
  #
  # @calls {search_model}
  def bu_autocomplete
    methods = search_model(Methods.order('name'), ["name"], params[:term])

    methods = methods.to_a.map do |item|
      {
        label: item.name,
        value: item.id
      }
    end

    methods = methods.unshift({ label: "[no value]", value: nil })

    respond_to do |format|
      format.json { render :json => methods }
    end
  end

  # GET /methods
  # GET /methods.xml
  def index
    if params[:format].nil? or params[:format] == 'html'
      @iteration = params[:iteration][/\d+/] rescue 1
      @methods = Methods.sorted_order("#{sort_column('methods','name')} #{sort_direction}").search(params[:search]).paginate(
        :page => params[:page], 
        :per_page => params[:DataTables_Table_0_length]
      )
      log_searches(Methods)
    else # Allow url queries of data, with scopes, only xml & csv ( & json? )
      @methods = Methods.api_search(params)
      log_searches(Methods.method(:api_search), params)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xml  { render :xml => @methods }
    end
  end

  # GET /methods/1
  # GET /methods/1.xml
  def show
    @method = Methods.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @method }
    end
  end

  # GET /methods/new
  # GET /methods/new.xml
  def new
    @method = Methods.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @method }
    end
  end

  # GET /methods/1/edit
  def edit
    @method = Methods.find(params[:id])
  end

  # POST /methods
  # POST /methods.xml
  def create
    @method = Methods.new(params[:methods])

    respond_to do |format|
      if @method.save
        format.html { redirect_to(@method, :notice => 'Method was successfully created.') }
        format.xml  { render :xml => @method, :status => :created, :location => @method }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @method.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /methods/1
  # PUT /methods/1.xml
  def update
    @method = Methods.find(params[:id])

    respond_to do |format|
      if @method.update_attributes(params[:methods])
        format.html { redirect_to(@method, :notice => 'Method was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @method.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /methods/1
  # DELETE /methods/1.xml
  def destroy
    @method = Methods.find(params[:id])
    @method.destroy

    respond_to do |format|
      format.html { redirect_to(methods_url) }
      format.xml  { head :ok }
    end
  end

end
