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

    get_insertion_data

    @displayed_columns = Trait.columns.select { |col| !['id', 'created_at', 'updated_at'].include?(col.name) }
  end

  # step 5
  def insert_data
     # reads CSV file and sets @data and @headers
    read_data
    get_insertion_data

    @data.each do |row|
      logger.info("about to insert #{row.inspect}")
      Trait.create(row)
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

  # Uses the session value of mapping to change @data from a CSV object to an Array of Hashes suitable for inserting into the traits table.
  def get_insertion_data
    mapping = session[:mapping]
    default_values = mapping["value"]

    insertion_data = Array.new
    @data.each do |csv_row|
      csv_row_as_hash = csv_row.to_hash

      # look up scientificname to get specie_id (if needed)
      species_key = nil
      if @headers.include?("scientificname")
        species_key = "scientificname"
      elsif @headers.include?("species.scientificname")
        species_key = "species.scientificname"
      end
      if !species_key.nil?
        sp = nil
        begin
          sp = Specie.find_by_scientificname(csv_row_as_hash[species_key])
        rescue
        end
        csv_row_as_hash["specie_id"] = sp ? sp.id.to_s : "NOT FOUND"
      end

      insertion_row = default_values.merge(csv_row_as_hash)

      # eliminate extraneous data from CSV row
      insertion_row.keep_if { |key, value| Trait.columns.collect { |column| column.name }.include?(key) }

      insertion_data << insertion_row

    end

    @data = insertion_data
  end

end
