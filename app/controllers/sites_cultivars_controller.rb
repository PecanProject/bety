class SitesCultivarsController < ApplicationController
  before_filter :login_required, :except => [ :show ]

  require 'csv'

  # GET /sites
  # GET /sites.xml
  def index
    request.format = :xml if params[:format].nil?

    # We have a lot of params and they or may not have to be
    # passed as conditions this is my way of adding them to conditions
    # if need be

    conditions = {}
    params.each do |k,v|
      next if !SitesCultivars.column_names.include?(k)
      conditions[k] = v
    end
    logger.info conditions.to_yaml
    sitescultivars = SitesCultivars.where(conditions)

    respond_to do |format|
      format.xml { render :xml => sitescultivars }
      format.csv { render :csv => sitescultivars }
      format.json { render :json => sitescultivars }
    end
  end

  # GET /cultivars/new
  # GET /cultivars/new.xml
  def new
    sitescultivars = SitesCultivars.new

    respond_to do |format|
      format.xml { render :xml => sitescultivars }
      format.csv { render :csv => sitescultivars }
      format.json { render :json => sitescultivars }
    end
  end

  # POST /cultivars
  # POST /cultivars.xml
  def create
    sitescultivars = SitesCultivars.new(params[:sitescultivars])

    respond_to do |format|
      if citationssites.save
        format.xml  { render :xml => sitescultivars, :status => :created }
        format.csv  { render :csv => sitescultivars, :status => :created }
        format.json  { render :json => sitescultivars, :status => :created }
      else
        format.xml  { render :xml => sitescultivars.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => sitescultivars.errors, :status => :unprocessable_entity }
        format.json  { render :json => sitescultivars.errors, :status => :unprocessable_entity }
      end
    end
  end

end
