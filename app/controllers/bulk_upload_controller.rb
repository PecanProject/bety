class BulkUploadController < ApplicationController

  def start_upload
  end

  def finish_upload

    # hard code trait columns for now
    @columns = Trait.columns
    @displayed_columns = @columns.select { |col| !['id', 'created_at', 'updated_at'].include?(col.name) }

    # get CSV file path
    session[:csv_file_path] = @csv_file_path = params["CSV file"].path

    begin
      csv = CSV.open(params["CSV file"].path, { headers: true }) # CSV.new(data, { headers: true })
      csv.readline
      @headers = session[:headers] = csv.headers
      
      data = csv.read # force exception if not well formed

      rows_of_hashes = []

      data.each do |row|
        rows_of_hashes << row.to_hash
      end

      @data_json = ActiveSupport::JSON.encode(rows_of_hashes)
      csv.rewind

      @displayed_columns_json = ActiveSupport::JSON.encode(@displayed_columns.map { |col| col.name })

      @data = csv
    rescue CSV::MalformedCSVError => e
      @errors = e
    end

    respond_to do |format|
      format.html {
        if @errors
          render action: "start_upload"
        else
          render
        end
      }
    end
  end


  # These are the stages handled by finish_upload:

  # display_CSV_stage

  # mapping_stage
  def map_data
    #@headers = session[:headers]

    respond_to do |format|
      format.js { render layout: false }
    end
  end

  # validation_stage
  def confirm_data
    

    respond_to do |format|
      format.js { render :layout => false }
    end
  end


    

end
