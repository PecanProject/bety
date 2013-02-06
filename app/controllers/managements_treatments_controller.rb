class ManagementsTreatmentsController < ApplicationController
  before_filter :login_required, :except => [ :show ]

  require 'csv'

  # GET /managementstreatments
  # GET /managementstreatments.xml
  def index
    params[:format] = 'xml' if params[:format].nil?

    # We have a lot of params and they or may not have to be
    # passed as conditions this is my way of adding them to conditions
    # if need be

    conditions = {}
    params.each do |k,v|
      next if !ManagementsTreatments.column_names.include?(k)
      conditions[k] = v
    end
    logger.info conditions.to_yaml
    managementstreatments = ManagementsTreatments.where(conditions)

    respond_to do |format|
      format.xml { render :xml => managementstreatments }
      format.csv { render :csv => managementstreatments }
      format.json { render :json => managementstreatments }
    end
  end

  # GET /managementstreatments/new
  # GET /managementstreatments/new.xml
  def new
    managementstreatments = ManagementsTreatments.new

    respond_to do |format|
      format.xml { render :xml => managementstreatments }
      format.csv { render :csv => managementstreatments }
      format.json { render :json => managementstreatments }
    end
  end

  # POST /managementstreatments
  # POST /managementstreatments.xml
  def create
    managementstreatments = ManagementsTreatments.new(params[:managements_treatments])

    respond_to do |format|
      if managementstreatments.save
        format.xml  { render :xml => managementstreatments, :status => :created }
        format.csv  { render :csv => managementstreatments, :status => :created }
        format.json  { render :json => managementstreatments, :status => :created }
      else
        format.xml  { render :xml => managementstreatments.errors, :status => :unprocessable_entity }
        format.csv  { render :csv => managementstreatments.errors, :status => :unprocessable_entity }
        format.json  { render :json => managementstreatments.errors, :status => :unprocessable_entity }
      end
    end
  end

end


