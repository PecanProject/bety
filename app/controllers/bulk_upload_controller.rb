class BulkUploadController < ApplicationController

  # step 1: Choose a file to upload.
  def start_upload
    # To-do: decide whether to display raw content of CSV file when we can't parse it.
#    if flash[:display_csv_file]
#      read_raw_contents
#    end
    # clean session upload data
    session[:csvpath] = nil
    session[:global_values] = {}
  end

  # step 2: Display the CSV file as a table.
  def display_csv_file

    begin
      # Store the selected CSV file if we got here via the "upload file" button:
      if params["new upload"]
        uploaded_io = params["CSV file"]
        if uploaded_io
          @data_set = BulkUploadDataSet.new(session, uploaded_io)
        else
          # blank submission; no file was chosen
          flash[:error] = "No file chosen"
          redirect_to(action: "start_upload")
          return # we're done here
        end
      else
        @data_set = BulkUploadDataSet.new(session)
      end

      # Remove the linked citation if the file includes citation data:
      if !session[:citation].nil? &&
          (@data_set.headers.include?("citation_author") || 
           @data_set.headers.include?("citation_doi"))

        flash.now[:warning] = "Removing linked citation since you have citation information in your data set"
        session[:citation] = nil

      end

    rescue CSV::MalformedCSVError => e
      flash[:error] = "Couldn't parse #{File.basename(session[:csvpath])}: #{e.message}"
      # flash[:display_csv_file] = true
      redirect_to(action: "start_upload")
      return
    rescue Exception => e # catches invalid UTF-8 byte sequence errors and empty lines
      flash[:error] = e.message
      redirect_to(action: "start_upload")
      return
    end

    @data_set.check_header_list # initializes @validation_summary and @validation_summary[:field_list_errors]

    if @data_set.validation_summary[:field_list_errors].any?
      # to do: decide whether to go on to validate data even when there are errors in the heading field list
#      return
    end

    # No heading errors; go on to validate data
    @data_set.validate_csv_data(session)
  end


  # step 3
  def choose_global_data_values
    @data_set = BulkUploadDataSet.new(session)
    @session = session # needed for sticky form fields
  end
    
=begin
  def map_data
    # reads CSV file and sets @data and @headers
    read_data # uses session[:csvpath] to set @headers and @data
    @displayed_columns = displayed_columns
  end
=end

  # step 4
  def confirm_data
    if params["global_values"]
      session[:global_values] = params["global_values"]
      session[:rounding] = params["rounding"]
    end
    @data_set = BulkUploadDataSet.new(session)
    @upload_sites = @data_set.get_upload_sites
  end

  # step 5
  def insert_data
    @data_set = BulkUploadDataSet.new(session)

    begin
      insertion_data = @data_set.get_insertion_data
    rescue => e
      flash[:error] = e.message
      logger.debug { "#{e.message}\n#{e.backtrace.join("\n")}" }
      redirect_to(:back)
      return
    end
    
    errors = nil
    begin
      Yield.transaction do
        insertion_data.each do |row|
          Yield.create!(row)
        end
      end
    rescue => e
      errors = e.message
      logger.debug { "#{e.message}\n#{e.backtrace.join("\n")}" }
    end

    respond_to do |format|
      format.html {
        if errors
          flash[:error] = errors
          redirect_to(:back)
        else
          flash[:success] = "Data was successfully uploaded."
          redirect_to(action: "start_upload")
        end
      }
    end
  end
    



################################################################################
  private

  
  def store_file(uploaded_io)
    file = File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb')
    file.write(uploaded_io.read)
    session[:csvpath] = file.path
    file.close
  end

  def read_raw_contents
    csvpath = session[:csvpath]
    csv = File.open(csvpath)
    @file_contents = csv.read
    csv.close
  end

  def displayed_columns
    Trait.columns.select { |col| !['id', 'created_at', 'updated_at'].include?(col.name) }
  end

  def validate(user_supplied_data)
    @global_errors ||= []
    user_supplied_data.each do |column, value|
      if value.nil? or value.to_s.empty?
        next
      end
      if column.match(/_id$/)
        tablename = column.sub(/_id$/, '').classify
        if tablename == "Method"
          tablename = "Methods"
        end
        table = tablename.constantize
        logger.info("table is #{tablename}")
        if !table.find_by_id(value)
          @global_errors << "Couldn't find row with id #{value} in table #{tablename}"
        end
      end
    end
  end


end
