class CitationsSitesController < ApplicationController
  before_filter :login_required, :except => [ :show ]

  require 'csv'

  # GET /sites
  # GET /sites.xml
  def index
    params[:format] = 'xml' if params[:format].nil?

    # We have a lot of params and they or may not have to be
    # passed as conditions this is my way of adding them to conditions
    # if need be

    conditions = {}
    params.each do |k,v|
      next if !CitationsSites.column_names.include?(k)
      conditions[k] = v
    end
    logger.info conditions.to_yaml
    citationssites = CitationsSites.where(conditions)

    respond_to do |format|
      format.xml { render :xml => citationssites }
      format.csv { render :csv => citationssites }
      format.json { render :json => citationssites }
    end
  end

  # GET /citations/new
  # GET /citations/new.xml
  def new
    citationssites = CitationsSites.new

    respond_to do |format|
      format.xml { render :xml => citationssites }
      format.csv { render :csv => citationssites }
      format.json { render :json => citationssites }
    end
  end

  # POST /citations
  # POST /citations.xml
  def create
    citationssites = CitationsSites.new(params[:citations_sites])

    respond_to do |format|
      if citationssites.save
        format.xml  { render :xml => citationssites, :status => :created }
        format.csv  { render :csv => citationssites, :status => :created }
        format.json  { render :json => citationssites, :status => :created }
      else
        format.xml  { render :xml => citationssites.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => citationssites.errors, :status => :unprocessable_entity }
        format.json  { render :json => citationssites.errors, :status => :unprocessable_entity }
      end
    end
  end

end
