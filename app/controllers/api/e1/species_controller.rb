class Api::E1::SpeciesController < Api::E1::BaseController

  respond_to :json

  def index
    respond_with query(Specie, params)
  end

  def show
    respond_with Specie.find(params[:id])
  end

end
