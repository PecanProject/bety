class InputsRunsController < ApplicationController
  before_action :login_required, :except => [ :show ]

  require 'csv'

  # GET /inputsruns
  # GET /inputsruns.xml
  def index
    params[:format] = 'xml' if params[:format].nil?

    # We have a lot of params and they or may not have to be
    # passed as conditions this is my way of adding them to conditions
    # if need be

    conditions = {}
    params.each do |k,v|
      next if !InputsRuns.column_names.include?(k)
      conditions[k] = v
    end
    logger.info conditions.to_yaml
    inputsruns = InputsRuns.where(conditions)

    respond_to do |format|
      format.xml { render :xml => inputsruns }
      format.csv { render :csv => inputsruns }
      format.json { render :json => inputsruns }
    end
  end

  # GET /inputsruns/new
  # GET /inputsruns/new.xml
  def new
    inputsruns = InputsRuns.new

    respond_to do |format|
      format.xml { render :xml => inputsruns }
      format.csv { render :csv => inputsruns }
      format.json { render :json => inputsruns }
    end
  end

  # POST /inputsruns
  # POST /inputsruns.xml
  def create
    inputsruns = InputsRuns.new(params[:inputs_runs])

    respond_to do |format|
      if inputsruns.save
        format.xml  { render :xml => inputsruns, :status => :created }
        format.csv  { render :csv => inputsruns, :status => :created }
        format.json  { render :json => inputsruns, :status => :created }
      else
        format.xml  { render :xml => inputsruns.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => inputsruns.errors, :status => :unprocessable_entity }
        format.json  { render :json => inputsruns.errors, :status => :unprocessable_entity }
      end
    end
  end

end
