class BulkUploadController < ApplicationController

  # step 1: Choose a file to upload.
  def start_upload
  end

  # step 2: Display the CSV file as a table.
  #
  # Session variables set:
  #     "csvpath", the path to where the uploaded file is stored
  # Instance variables set:
  #     @data, a CSV object containing the CSV file data
  #     @headers, an array of the headers of the CSV file; equals the corresponding session variable
  #     @errors (if there are any)
  def display_csv_file

    if params["CSV file"]
      uploaded_io = params["CSV file"]
      file = File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb')
      file.write(uploaded_io.read)
      session[:csvpath] = file.path

      begin
        # reads CSV file and sets @data and @headers
        read_data

        @data.read # force exception if not well formed
        @data.rewind # rewinds to the first line after the header

      rescue CSV::MalformedCSVError => e
        @errors = e
      end

    else
      @errors = "No file chosen"
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


  # step 3
  def map_data
    # reads CSV file and sets @data and @headers
    read_data
    @displayed_columns = Trait.columns.select { |col| !['id', 'created_at', 'updated_at'].include?(col.name) }
  end


  # step 4
  def confirm_data
    # reads CSV file and sets @data and @headers
    read_data
    session[:mapping] = params["mapping"]

    # look up scientificname to get specie_id (if needed)
    species_key = nil
    if @headers.include?("scientificname")
      species_key = "scientificname"
    elsif @headers.include?("species.scientificname")
      species_key = "species.scientificname"
    end

    if !species_key.nil?
      data_copy = Array.new
      @data.each do |row|
        row = row.to_hash
        sp = nil
        begin
          sp = Specie.find_by_scientificname(row[species_key])
        rescue
        end
        row["specie_id"] = sp ? sp.id.to_s : "NOT FOUND"
        data_copy << row
      end
      @data = data_copy
    end

    @displayed_columns = Trait.columns.select { |col| !['id', 'created_at', 'updated_at'].include?(col.name) }
  end

  # step 5
  def insert_data
     # reads CSV file and sets @data and @headers
    read_data

    @data.each do |row|
      Trait.new()
    end



    render action: "start_upload"
  end
    




  private
  # Uses: 
  #     session[:csvpath], the path to the uploaded CSV file
  # Sets:
  #     @headers, the CSV file's header info
  #     @data, a CSV object corresponding to the uploaded file,
  #         positioned to read the first line after the header line
  def read_data
    
    csvpath = session[:csvpath]
    
    csv = CSV.open(csvpath, { headers: true })
    csv.readline # need to read first line to get headers
    @headers = csv.headers

    # store CSV object in instance variable
    @data = csv

  end

end
