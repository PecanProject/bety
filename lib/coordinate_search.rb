module CoordinateSearch
  # degrees lat ~ miles/69.1
  # degrees lng ~ miles/53.0 (at the 40th parallels)
  def coordinate_search(params)
    if (!params[:lat] || !params[:lng] || !params[:radius] ||
        params[:lat] == '' || !params[:lng] == '' || params[:radius] == '')
      # Don't restrict by map location:
      where({})
    else
      logger.info(params)
      lat = params[:lat][/-?\d+\.?\d*/].to_f
      lon = params[:lng][/-?\d+\.?\d*/].to_f
      radius = params[:radius].to_i

      where({ :lat => (lat - (radius/69.1))..(lat + (radius/69.1)),
              :lon => (lon - (radius/53.0))..(lon + (radius/53.0)) })
    end
  end

end
