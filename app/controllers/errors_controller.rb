require 'net/https'
require 'uri'

class ErrorsController < ApplicationController

  before_filter :login_required 

  layout 'application'

  $bety_managers = { 26 => "Lauren Hostert", 1 => "Patrick Mulrooney", 3 => "David LeBauer", 6 => "Mike Dietze", 8 => "Deepak Jaiswal", 9 => "Carl Davidson", 15 => "Xiaohui Feng", 23 => "Ryan Kelly", 30 => "Steve Long" }

  # GET /errors
  # GET /errors.xml
  def index

    @src = params[:src]

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # POST /errors
  # POST /errors.xml
  def create
    xml = "<issue>"
    xml += "<project name='BETY-db' id='1'/>"
    xml += "<tracker name='Bug' id='1'/>"
    xml += "<status name='New' id='1'/>"
    xml += "<priority name='Normal' id='4'/>"
    xml += "<author name='BETY Bug Report' id='32'/>"
    xml += "<assigned_to name='#{$bety_managers[params[:error][:assign_to].to_i]}' id='#{params[:error][:assign_to]}'/>"
    xml += "<subject>#{params[:error][:url].to_xs}</subject>"
    xml += "<description>#{params[:error][:message].to_xs}</description>"
    xml += "</issue>'"
    json = "{'issue':{'project_id':1,'tracker_id':1,'status_id':1,'priority_id':4,'author_id':32,'assigned_to_id':#{params[:error][:assign_to]},'subject':'#{params[:error][:url].to_xs}','description':'#{params[:error][:message].to_xs}'}}"

    logger.info xml
    logger.info json

    uri = URI.parse("https://ebi-forecast.igb.illinois.edu/redmine/projects/bety-db/issues.xml")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.basic_auth "betybug", "ch#pRUr9"
    #request.body = xml
    request.body = json
    request.content_type = "application/json"
    response = http.request(request)

    respond_to do |format|
      if response.header["status"] == "201"
        flash[:notice] = 'Bug was successfully reported.'
        format.html { render :action => "index" }
      else
        flash[:notice] = 'Sorry something went wrong. Please try again.'
        format.html { render :action => "index" }
      end
    end
  end
end
