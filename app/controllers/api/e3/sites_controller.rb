class Api::E3::SitesController < Api::E3::BaseController

  def index
    @sites = query(Site, params)
  end

  def show
    @site = Site.find(params[:id])
  end

end
