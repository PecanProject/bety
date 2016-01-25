class Api::E1::SitesController < Api::E1::BaseController

  respond_to :json

  def index
    respond_with query(Site, params)
  end

  def show
    respond_with Site.find(params[:id])
  end

end
