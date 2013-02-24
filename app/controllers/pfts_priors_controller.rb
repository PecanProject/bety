class PftsPriorsController < ApplicationController
  before_filter :login_required, :except => [ :show ]

  require 'csv'

  # GET /pftspriors
  # GET /pftspriors.xml
  def index
    params[:format] = 'xml' if params[:format].nil?

    # We have a lot of params and they or may not have to be
    # passed as conditions this is my way of adding them to conditions
    # if need be

    conditions = {}
    params.each do |k,v|
      next if !PftsPriors.column_names.include?(k)
      conditions[k] = v
    end
    logger.info conditions.to_yaml
    pftspriors = PftsPriors.where(conditions)

    respond_to do |format|
      format.xml { render :xml => pftspriors }
      format.csv { render :csv => pftspriors }
      format.json { render :json => pftspriors }
    end
  end

  # GET /pftspriors/new
  # GET /pftspriors/new.xml
  def new
    pftspriors = PftsPriors.new

    respond_to do |format|
      format.xml { render :xml => pftspriors }
      format.csv { render :csv => pftspriors }
      format.json { render :json => pftspriors }
    end
  end

  # POST /pftspriors
  # POST /pftspriors.xml
  def create
    pftspriors = PftsPriors.new(params[:pfts_priors])

    respond_to do |format|
      if pftspriors.save
        format.xml  { render :xml => pftspriors, :status => :created }
        format.csv  { render :csv => pftspriors, :status => :created }
        format.json  { render :json => pftspriors, :status => :created }
      else
        format.xml  { render :xml => pftspriors.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => pftspriors.errors, :status => :unprocessable_entity }
        format.json  { render :json => pftspriors.errors, :status => :unprocessable_entity }
      end
    end
  end

end
