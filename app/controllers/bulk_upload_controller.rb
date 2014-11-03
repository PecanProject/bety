# Controller for the Bulk Upload wizard.  The steps of the wizard are
# 1. start_upload::
#
#    The user is presented with a form for choosing a file to upload.
#
# 1. display_csv_file::
#
#    The results of validating the header list and data in the file are
#    displayed.  The page for this stage is displayed only if the upload
#    succeeds and the uploaded file is well-formed.
#
# 1. choose_global_data_values::
#
#    The user is presented with a form for choosing global (dataset-wide) values
#    and options.  The page for this stage is displayed only if the headers and
#    data in the uploaded file validate.
#
# 1. confirm_data::
#
#    A summary of existing data referred to by the data set.  This allows the
#    user to verify the citations, sites, species, and cultivars referred to by
#    the data set or selected interactively are correct.
#
# 1. insert_data::
#
#    No page corresponds to this action.
#
# At each stage, the current stage is recorded in the +:bulk_upload_stage+ key
# of the session variable.
class BulkUploadController < ApplicationController

  before_filter :login_required
  before_filter :record_stage
  before_filter :clear_session_data, only: :start_upload
  before_filter :valid_file_required, only: [ :choose_global_data_values, :confirm_data, :insert_data ]

  private

  def record_stage
    session[:bulk_upload_stage] = params[:action]
  end

  def clear_session_data
    session.delete_if do |key|
      # delete bulk-upload-related session data (except for :citation,
      # which is "global"):
      ["csvpath", "global_values", "rounding", "citation_id_list",
      "number_of_rows", "valid_upload_file"].include?(key)
    end
  end

  def valid_file_required
    # Don't allow access if we don't have a valid file:
    if !session[:valid_upload_file]
      redirect_to(action: "display_csv_file")
      return
    end
  end

  public

  # Step 1: Choose a file to upload.
  #
  # The bulk-upload-related session keys--namely "csvpath", "global_values",
  # "rounding", and "citation_id_list"--are cleared at the start of this action,
  # and the +:bulk_upload_stage+ session key is set to this action.
  def start_upload
    # To-do: decide whether to display raw content of CSV file when we can't parse it.
#    if flash[:display_csv_file]
#      read_raw_contents
#    end
  end

  # Step 2: Choose a citation.
  #
  # This step is skipped if the file contains citation information.
  def choose_global_citation
    if !session[:csvpath]
        # Blank submission--no file was chosen.  We should never get here unless
        # the user directly enters the URL for this action without having
        # uploaded a file.
        flash[:error] = "No file chosen"
        redirect_to(action: "start_upload")
    end

    @session = session # needed for sticky form fields
  end

  # Step 3: Display the CSV file as a table.
  #
  # If the +params+ key "new upload" is set (i.e., we got to this action by
  # posting the form on the +start_upload+ page), the "CSV file" parameter is
  # used to instantiate a new +BulkUploadDataSet+, the file contents are copied
  # to a new file stored in the +public/uploads+ directory, and the location of
  # this file is stored in the +:csvpath+ key of the session.  If no file was
  # provided or if the uploaded file is malformed, instantiation fails and the
  # user is redirected back to the +start_upload+ page.
  #
  # If the +params+ key "new upload" is _not_ set (i.e., we are returning to
  # this page without having completed the wizard and without having returned to
  # the +start_upload+ page), the location of the uploaded file is looked up in
  # the +:csvpath+ key of the session and used to instantiate a new
  # +BulkUplaodDataSet+.  The file is not re-checked for well-formedness.
  #
  # After successful instantiation of +BulkUploadDataSet+, its
  # +#check_header_list+ method is run to initialize its +validation_summary+
  # attribute and set the value of the +:field_list_errors+ key.  Then its
  # +#validate_csv_data+ method is run, which sets or alters the following
  # attributes:
  # * +validation_summary+::
  #
  #    (keys and a corresponding value list for each type of error found are
  #    added)
  #
  # * +validated_data+::
  #
  #    (essentially, the data in the file with validation-related meta-data
  #    added)
  #
  # * +field_list_error_count+::
  # * +data_value_error_count+::
  # * +total_error_count+::
  # * +file_has_fatal_errors+.::
  def display_csv_file

    uploaded_io = params["CSV file"]
    if uploaded_io
      # we got here via the "upload file" button
      @data_set = BulkUploadDataSet.new(session, uploaded_io)
    elsif session[:csvpath]
      # we returned here with after previously uploading the file
      @data_set = BulkUploadDataSet.new(session)
    else
      # blank submission; no file was chosen
      flash[:error] = "No file chosen"
      redirect_to(action: "start_upload")
      return # we're done here
    end



    ### Ensure we have a citation -- either in the file or stored in the
    ### session, but not both.  Remove the session citaion and/or go to the
    ### citation selection page if needed.

    # Case 1: We got here from the "choose_global_citation" page:
    if params[:global_values]
      if params[:global_values][:citation_id].empty?
        flash[:error] = "No citation selected"
        redirect_to(:back)
        return
      end
      if  !session[:citation].nil?
        flash.now[:warning] = "Replacing citation #{Citation.find(session[:citation]).to_s} with #{params["global_values"][":citation"].inspect}."
      end
      session[:citation] = params[:global_values][:citation_id]
    end

    # Remove the linked citation if the file includes citation data:
    if !session[:citation].nil? && @data_set.file_includes_citation_info

      # Case 2: The citation information both in the session and in the file; remove the session citation:

      flash.now[:warning] = "Removing linked citation since you have citation information in your data set"
      session[:citation] = nil

    elsif @data_set.needs_citation_selection

      # Case 3: There is no citation information in either the session or the file; present a form to select one:
      redirect_to(action: "choose_global_citation")
      return
    end

    # If we get here, there is citation information either in the session or the file, but not both.





    @data_set.check_header_list # initializes @validation_summary and @validation_summary[:field_list_errors]

    if @data_set.validation_summary[:field_list_errors].any?
      # to do: decide whether to go on to validate data even when there are errors in the heading field list
      #      return
    end

    # No heading errors; go on to validate data
    @data_set.validate_csv_data

    if !@data_set.file_has_fatal_errors
      session[:valid_upload_file] = true
    end

  rescue CSV::MalformedCSVError => e
    flash[:error] = "Couldn't parse #{File.basename(session[:csvpath])}: #{e.message}"
    # flash[:display_csv_file] = true
    redirect_to(action: "start_upload")
    return
  rescue NoDataError => e
    flash[:error] = e.message
  rescue Exception => e # catches invalid UTF-8 byte sequence errors and empty lines
    flash[:error] = e.message
    logger.debug { "#{e.message}\n#{e.backtrace.join("\n")}" }
    redirect_to(action: "start_upload")
    return
  end


  # Step 4: Choose global (dataset-wide) values and options.
  #
  # The user is presented with a form to choose:
  # 1. The amount of rounding to use for yield values
  # 1. Dataset-wide values for attributes of the data not specified in the
  #    upload file, which may be any of:
  #    a. The site.
  #    a. The species.
  #    a. The treatment.
  #    a. The access_level.
  #    a. The cultivar.
  #    a. The date.
  # Any values specified are saved as session data upon form submission.
  def choose_global_data_values
    @data_set = BulkUploadDataSet.new(session)
    @session = session # needed for sticky form fields
    @placeholders = {
      site: "Enter any portion of the site name, city, state, or country",
      species: "Enter the first few letters of the scientific name",
      treatement: "Enter any portion of the treatment name",
      cultivar: "(optional)"
    }
  end

  # Step 5: Confirm data.
  #
  # This page displays the the citations, sites, species, and cultivars referred
  # to by the data set or selected interactively.  The helps assure the proper
  # associations will be made when the data is inserted.  An +Insesrt Data+
  # button is displayed for the user to trigger the final step after visually
  # verifying the data.
  def confirm_data
    if params["global_values"]
      session[:global_values] = params["global_values"]
      if params["global_values"]["date"]
        BulkUploadDataSet.validate_date(params["global_values"]["date"])
      end
      if params["global_values"]["access_level"]
        if !(1..4).include? params["global_values"]["access_level"].to_i
          raise "You must select an access level"
        end
      end
    end

    if params["rounding"]
      session[:rounding] = params["rounding"]
    end

    # This takes care of the case where the user attempts to go to this page
    # without ever having submitted the form on the "choose_global_data_values"
    # page:
    if session[:rounding].nil?
      redirect_to(action: "choose_global_data_values")
      return
    end

    @data_set = BulkUploadDataSet.new(session)

    @upload_sites = @data_set.get_upload_sites
    @upload_species = @data_set.get_upload_species
    @upload_citations = @data_set.get_upload_citations
    @upload_treatments = @data_set.get_upload_treatments
    @upload_cultivars = @data_set.get_upload_cultivars
    logger.debug("cultivars = #{@upload_cultivars}")
  rescue => e
    flash[:error] = e.message
    logger.debug { "#{e.message}\n#{e.backtrace.join("\n")}" }
    redirect_to(action: "choose_global_data_values")
  end

  # Step 6: Insert the data from the data file in accordance with any
  # interactively-specified options.
  #
  # Data is inserted within a database transaction so that any failure rolls
  # back the entire transaction.
  def insert_data
    # This takes care of the case where the user attempts to insert data
    # without ever having submitted the form on the "choose_global_data_values"
    # page:
    if session[:rounding].nil?
      redirect_to(action: "choose_global_data_values")
      return
    end

    @data_set = BulkUploadDataSet.new(session)

    @data_set.insert_data

    respond_to do |format|
      format.html {
        flash[:success] = "Data from #{File.basename(session[:csvpath])} was successfully uploaded."
        redirect_to(action: "start_upload")
      }
    end

  rescue => e
    flash[:error] = e.message
    logger.debug { "#{e.message}\n#{e.backtrace.join("\n")}" }
    redirect_to(action: "choose_global_data_values")
    return
  end

################################################################################
  private

  def read_raw_contents
    csvpath = session[:csvpath]
    csv = File.open(csvpath)
    @file_contents = csv.read
    csv.close
  end

end
