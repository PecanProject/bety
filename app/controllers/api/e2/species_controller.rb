class Api::E2::SpeciesController < Api::E2::BaseController

  respond_to :json

  def index
    respond_with query(Specie, params)
  end

  def show
    respond_with Specie.find(params[:id])
  end

end
