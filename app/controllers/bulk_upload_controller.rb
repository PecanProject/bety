class BulkUploadController < ApplicationController
  def start_upload
  end

  def confirm_data

    csv = CSV.open(params["CSV file"].path, { headers: true }) # CSV.new(data, { headers: true })
    
    csv.readline

    session[:headers] = @headers = csv.headers

    @data = csv
  end

  def map_data

    # hard code trait columns for now

    @columns = Trait.columns

    logger.info(@columns[0].inspect)

    @headers = session[:headers] || "???"
    
  end


    

end
