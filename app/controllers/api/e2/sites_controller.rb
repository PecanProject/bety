class Api::E2::SitesController < Api::E2::BaseController

  respond_to :json

  def index
    respond_with query(Site, params)
  end

  def show
    respond_with Site.find(params[:id])
  end

end
