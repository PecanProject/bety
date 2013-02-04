class PosteriorsRunsController < ApplicationController
  before_filter :login_required, :except => [ :show ]

  require 'csv'

  # GET /posteriorsruns
  # GET /posteriorsruns.xml
  def index
    params[:format] = 'xml' if params[:format].nil?

    # We have a lot of params and they or may not have to be
    # passed as conditions this is my way of adding them to conditions
    # if need be

    conditions = {}
    params.each do |k,v|
      next if !PosteriorsRuns.column_names.include?(k)
      conditions[k] = v
    end
    logger.info conditions.to_yaml
    posteriorsruns = PosteriorsRuns.where(conditions)

    respond_to do |format|
      format.xml { render :xml => posteriorsruns }
      format.csv { render :csv => posteriorsruns }
      format.json { render :json => posteriorsruns }
    end
  end

  # GET /posteriorsruns/new
  # GET /posteriorsruns/new.xml
  def new
    posteriorsruns = PosteriorsRuns.new

    respond_to do |format|
      format.xml { render :xml => posteriorsruns }
      format.csv { render :csv => posteriorsruns }
      format.json { render :json => posteriorsruns }
    end
  end

  # POST /posteriorsruns
  # POST /posteriorsruns.xml
  def create
    posteriorsruns = PosteriorsRuns.new(params[:posteriors_runs])

    respond_to do |format|
      if posteriorsruns.save
        format.xml  { render :xml => posteriorsruns, :status => :created }
        format.csv  { render :csv => posteriorsruns, :status => :created }
        format.json  { render :json => posteriorsruns, :status => :created }
      else
        format.xml  { render :xml => posteriorsruns.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => posteriorsruns.errors, :status => :unprocessable_entity }
        format.json  { render :json => posteriorsruns.errors, :status => :unprocessable_entity }
      end
    end
  end

end
