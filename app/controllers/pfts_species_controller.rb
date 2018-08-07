class PftsSpeciesController < ApplicationController
  before_action :login_required, :except => [ :show ]

  require 'csv'

  # GET /pftsspecies
  # GET /pftsspecies.xml
  def index
    params[:format] = 'xml' if params[:format].nil?

    # We have a lot of params and they or may not have to be
    # passed as conditions this is my way of adding them to conditions
    # if need be

    conditions = {}
    params.each do |k,v|
      next if !PftsSpecies.column_names.include?(k)
      conditions[k] = v
    end
    logger.info conditions.to_yaml
    pftsspecies = PftsSpecies.where(conditions)

    respond_to do |format|
      format.xml { render :xml => pftsspecies }
      format.csv { render :csv => pftsspecies }
      format.json { render :json => pftsspecies }
    end
  end

  # GET /pftsspecies/new
  # GET /pftsspecies/new.xml
  def new
    pftsspecies = PftsSpecies.new

    respond_to do |format|
      format.xml { render :xml => pftsspecies }
      format.csv { render :csv => pftsspecies }
      format.json { render :json => pftsspecies }
    end
  end

  # POST /pftsspecies
  # POST /pftsspecies.xml
  def create
    pftsspecies = PftsSpecies.new(params[:pfts_species])

    respond_to do |format|
      if pftsspecies.save
        format.xml  { render :xml => pftsspecies, :status => :created }
        format.csv  { render :csv => pftsspecies, :status => :created }
        format.json  { render :json => pftsspecies, :status => :created }
      else
        format.xml  { render :xml => pftsspecies.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => pftsspecies.errors, :status => :unprocessable_entity }
        format.json  { render :json => pftsspecies.errors, :status => :unprocessable_entity }
      end
    end
  end

end

