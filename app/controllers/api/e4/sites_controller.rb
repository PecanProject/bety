class Api::E4::SitesController < Api::E4::BaseController

  def index
    @sites = query(Site, params)
  end

  def show
    @site = Site.find(params[:id])
  end

end
