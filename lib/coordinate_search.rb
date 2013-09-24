module CoordinateSearch

  #20 miles
  #lat ~ miles/69.1
  #lng ~ miles/53.0
  def coordinate_search(params)
    logger.info(params)
    lat = params[:lat][/-?\d+\.?\d*/].to_f
    lon = params[:lng][/-?\d+\.?\d*/].to_f
    radius = params[:radius].to_i

    where({ :lat => (lat-(radius/69.1))..(lat+(radius/69.1)),
            :lon => (lon-(radius/53.0))..(lon+(radius/53.0)) })
  end

end
