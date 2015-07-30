class MimetypesController < ApplicationController

  def autocomplete
    mimetypes = search_model(Mimetype.order(:type_string), %w( type_string ), params[:term])

    mimetypes = mimetypes.to_a.map do |item|
      {
        label: item.type_string,
        value: item.type_string
      }
    end

    respond_to do |format|
      format.json { render :json => mimetypes }
    end
  end

end
