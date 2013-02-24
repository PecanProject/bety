class CitationsTreatmentsController < ApplicationController
  before_filter :login_required, :except => [ :show ]

  require 'csv'

  # GET /citationstreatments
  # GET /citationstreatments.xml
  def index
    params[:format] = 'xml' if params[:format].nil?

    # We have a lot of params and they or may not have to be
    # passed as conditions this is my way of adding them to conditions
    # if need be

    conditions = {}
    params.each do |k,v|
      next if !CitationsTreatments.column_names.include?(k)
      conditions[k] = v
    end
    logger.info conditions.to_yaml
    citationstreatments = CitationsTreatments.where(conditions)

    respond_to do |format|
      format.xml { render :xml => citationstreatments }
      format.csv { render :csv => citationstreatments }
      format.json { render :json => citationstreatments }
    end
  end

  # GET /citationstreatments/new
  # GET /citationstreatments/new.xml
  def new
    citationstreatments = CitationsTreatments.new

    respond_to do |format|
      format.xml { render :xml => citationstreatments }
      format.csv { render :csv => citationstreatments }
      format.json { render :json => citationstreatments }
    end
  end

  # POST /citationstreatments
  # POST /citationstreatments.xml
  def create
    citationstreatments = CitationsTreatments.new(params[:citations_treatments])

    respond_to do |format|
      if citationstreatments.save
        format.xml  { render :xml => citationstreatments, :status => :created }
        format.csv  { render :csv => citationstreatments, :status => :created }
        format.json  { render :json => citationstreatments, :status => :created }
      else
        format.xml  { render :xml => citationstreatments.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => citationstreatments.errors, :status => :unprocessable_entity }
        format.json  { render :json => citationstreatments.errors, :status => :unprocessable_entity }
      end
    end
  end

end

