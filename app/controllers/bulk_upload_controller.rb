
#
# Controller for the Bulk Upload wizard.  The steps of the wizard are
#
#  1. {start_upload}
#
#     The user is presented with a form for choosing a file to upload.
#
#  1. {choose_global_citation}
#
#     The user is presented with a form for choosing a global (dataset-wide)
#     citation.  This page is skipped if there is citation data in the uploaded
#     file or if there is a selected citation stored in the browser session.
#     This and subsequent pages are displayed only if the upload succeeds and
#     the uploaded file is well-formed.
#
#  1. {display_csv_file}
#
#     The results of validating the header list and data in the file are
#     displayed.  This and subsequent pages are displayed only if the file
#     includes citation information or one was choosen interactively.
#
#  1. {choose_global_data_values}
#
#     The user is presented with a form for choosing global (dataset-wide) values
#     and options.  This and subsequent pages are displayed only if the headers
#     and data in the uploaded file validate.
#
#  1. {confirm_data}
#
#     A summary of existing data referred to by the data set.  This allows the
#     user to verify the citations, sites, species, and cultivars referred to by
#     the data set or selected interactively are correct.  If the upload is a
#     trait upload, the methods chosen for each trait variable are displayed as
#     well.  This page is displayed only if all required information has been
#     specified.
#
#  1. {insert_data}
#
#     No page corresponds to this action.  This action may be performed only if
#     all required information has been specified.
#
# At each stage, the current stage is recorded in the +:bulk_upload_stage+ key
# of the session variable.
class BulkUploadController < ApplicationController

  before_filter :login_required
  before_filter :record_stage
  before_filter :clear_session_data, only: :start_upload
  before_filter :valid_file_required, only: [ :choose_global_data_values, :confirm_data, :insert_data ]

  after_filter :record_bulk_upload_citation

  private

  # Records the current bulk upload action in the session so that if we step
  # outside the wizard, we can return to where we were.
  def record_stage
    session[:bulk_upload_stage] = params[:action]
  end

  # keep track of the last value session[:citation] was changed to within the
  # wizard; this way, we can catch it if it changes outside the wizard
  def record_bulk_upload_citation
    if !session[:file_includes_citation_info]
      session[:bulk_upload_citation] = session[:citation]
    end
  end

  # Clears all bulk-upload-related session data except the
  # bulk_upload_stage.  Used as a before_filter for {start_upload}.
  # @return [void]
  #
  # @side_effect Deletes most bulk-upload-related key-value pairs from the
  #   session.
  def clear_session_data
    ["csvpath", "global_values", "rounding", "citation_id_list",
    "number_of_rows", "valid_upload_file", "file_includes_citation_info",
    "bulk_upload_citation", "trait_to_method_mapping"].each do |key|
      session.delete key
    end
  end

  # Redirects to the "display_csv_file" page if the data file doesn't validate.
  def valid_file_required
    check_if_citation_changed
    # Don't allow access if we don't have a valid file:
    if !session[:valid_upload_file]
      redirect_to(action: "display_csv_file")
      return
    end
  end

  # Unmark the current upload file as valid if we changed the citation:
  def check_if_citation_changed
    if (!session[:file_includes_citation_info] &&
        session[:bulk_upload_citation] != session[:citation])
      session[:valid_upload_file] = nil
    end
  end

  public

  # Called by jQuery when user selects a method in an autocompletion
  # field on the "Specify Upload Options and Global Values" page.
  #
  # @preconditions `session[:trait_to_method_mapping]` exists and is a Hash
  #   (possibly empty).
  # @preconditions `params["method_info"]["label"]` and
  #   `params["method_info"]["value"]` exist and are the +name+ and +id+
  #   attributes of some method in the methods table.
  #
  # @return [void]
  #
  # @side_effect Adds to
  #   `session[:trait_to_method_mapping]` under the key corresponding to the
  #   value of the HTTP parameter "trait_name".  The corresponding value will be
  #   a Hash with keys +:method_name+ and +:method_id+.
  def store_trait_method_mapping_in_session
    session[:trait_to_method_mapping][params["trait_name"]] = {
      method_name: params["method_info"]["label"],
      method_id: params["method_info"]["value"]
    }
    render(nothing: true)
  end

  # Step 1: Choose a file to upload.
  #
  # The bulk-upload-related session keys--namely "csvpath", "global_values",
  # "rounding", "citation_id_list", "number_of_rows", "valid_upload_file", and
  # "file_includes_citation_info"--are cleared at the start of this action, and
  # the +:bulk_upload_stage+ session key is set to this action.
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

    if session[:file_includes_citation_info]
      # We shouldn't be here; go on to (or back to) the validation stage.
      redirect_to(action: "display_csv_file")
    end

    @session = session # needed for sticky form fields
  end

  # Step 3: Display the CSV file as a table.
  #
  # If the +params+ key "CSV file" is set (i.e., we got to this action by
  # posting the form on the +start_upload+ page), this parameter is used to
  # instantiate a new +BulkUploadDataSet+, the uploaded file is copied to the
  # +public/uploads+ directory, and the location of this file is stored in the
  # +:csvpath+ key of the session.  If no file was provided or if the uploaded
  # file is malformed, instantiation fails and the user is redirected back to
  # the +start_upload+ page.
  #
  # If the +params+ key "CSV file" is _not_ set but the session key +:csvpath+
  # exists (i.e., we are returning to this page without having completed the
  # wizard and without having returned to the +start_upload+ page; note that
  # this includes the case where we were sent back to the
  # +choose_global_citation+ page after an earlier visit to this page), the
  # location of the uploaded file is looked up in the +:csvpath+ key of the
  # session and used to instantiate a new +BulkUplaodDataSet+.  The file is not
  # re-checked for well-formedness.
  #
  # If neither the +params+ key "CSV file" nor the session key +:csvpath+ exist
  # (i.e., the user submitted a blank upload form or we didn't reach this page
  # through the normal flow of the wizard), the user is directed back to the
  # +start_upload+ page and receives a "No file chosen" error message.
  #
  # Once the file-related business is complete, the file is checked for citation
  # information.  If it includes none, and if there is no citation information
  # in the session, the user is sent back to the +choose_global_citation+ page.
  #
  # After successful instantiation of +BulkUploadDataSet+, its
  # +#check_header_list+ method is run to initialize its +validation_summary+
  # attribute and set the value of +validation_summary+[:field_list_errors].
  # Then its +#validate_csv_data+ method is run, which sets or alters the
  # following attributes:
  # * +validation_summary+::
  #
  #    This includes a key for each type of error found.  Under this key is
  #    stored a CSS class to associate with this type of error and a list of
  #    numbers of rows in which the error occurs.
  #
  # * +validated_data+::
  #
  #    This is essentially the data in the file but with validation-related
  #    meta-data added (provided there were no errors in the field list;
  #    otherwise, data validation is not done).
  #
  # @calls {BulkUploadDataSet#check_header_list},
  #   {BulkUploadDataSet#validate_csv_data}, {ensure_citation}
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
    ### session, but not both.  Remove the session citation and/or go to the
    ### citation selection page if needed.

    if params[:global_values]
      # we got here by submitting the form on the "Choose a Citation" page

      if params[:global_values][:citation_id].empty?
        # Since the form pre-populates the citation_id parameter with the
        # session citation (if there is one), we only get here if both (1) the
        # user submitted a blank form, and (2) there was no previously-selected
        # session citation.
        flash[:error] = "No citation selected"
        redirect_to(:back)
        return
      end

      if !session[:citation].nil? && session[:citation] != params[:global_values][:citation_id]
        flash.now[:warning] = "Replacing citation #{Citation.find(session[:citation]).to_s} with #{params["global_values"][":citation"].inspect}."
      end
      session[:citation] = params[:global_values][:citation_id]
    end

    session[:file_includes_citation_info] = @data_set.file_includes_citation_info

    begin
      ensure_citation
    rescue
      # This is considered "normal flow": this user got here by uploading a file
      # without citation info; don't display the exception error.
      redirect_to(action: "choose_global_citation")
      return
    end

    # If we get here, there is citation information either in the session or the file, but not both.





    @data_set.check_header_list # initializes @validation_summary and @validation_summary[:field_list_errors]


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
  #
  # * The amount of rounding to use for yield or trait variable values.
  # * The amount of rounding to use for the standard error (if included).
  # * Dataset-wide values for attributes of the data not specified in the
  #    upload file, which may be any of:
  #     * site
  #     * species
  #     * treatment
  #     * access_level
  #     * cultivar
  #     * date
  # * (For trait uploads only:) A method to associate with each trait variable.
  #
  # Any values specified are saved as session data upon form submission.
  #
  # @changed_instance_variable @data_set [BulkUploadDataSet]
  # @changed_instance_variable @heading_variable_info [Hash]
  # @changed_instance_variable @session This acts like a Hash.
  # @changed_instance_variable @placeholders [Hash]
  #
  # @calls {BulkUploadDataSet#initialize BulkUploadDataSet.new},
  #   {BulkUploadDataSet#get_variables_in_heading},
  #   {BulkUploadDataSet#heading_variable_info}, {ensure_citation}
  #
  # @side_effect (For trait uploads only:) The key `:trait_to_method_mapping` is
  #   added to the (persistent, global) `session` variable if it is not present.
  #   The corresponding value will be a Hash whose keys correspond to all trait
  #   variables in the upload file and whose values are all empty Hashes.
  def choose_global_data_values
    @data_set = BulkUploadDataSet.new(session)

    begin
      ensure_citation
    rescue => e
      flash[:error] = e.message
      redirect_to(action: "choose_global_citation")
      return
    end

    @data_set.get_variables_in_heading # sets @data_set.heading_variable_info
    @heading_variable_info = @data_set.heading_variable_info

    @session = session # needed for sticky form fields
    @placeholders = {
      site: "Enter any portion of the site name, city, state, or country",
      species: "Enter the first few letters of the scientific name",
      treatement: "Enter any portion of the treatment name",
      cultivar: "(optional)"
    }

    # If the trait-to-method mapping is not already stored in the
    # session, initialize it with a key for each trait variable and a
    # corresponding empty hash:
    if @data_set.trait_data? && !session.has_key?(:trait_to_method_mapping)
      mapping = {}
      @heading_variable_info.values.each { |info_hash| mapping[info_hash[:name]] = {} }
      session[:trait_to_method_mapping] = mapping
    end

  end

  # Step 5: Confirm data.
  #
  # This page displays the the citations, sites, species, and cultivars referred
  # to by the data set or selected interactively.  The helps ensure the proper
  # associations will be made when the data is inserted.  An `Insert Data`
  # button is displayed for the user to trigger the final step after visually
  # verifying the data.
  #
  # @changed_instance_variable @data_set [BulkUploadDataSet]
  # @changed_instance_variable @variable_to_covariates_mapping [Hash]
  # @changed_instance_variable @upload_sites [Array]
  # @changed_instance_variable @upload_entities [Array]
  # @changed_instance_variable @upload_species [Array]
  # @changed_instance_variable @upload_citations [Array]
  # @changed_instance_variable @upload_treatments [Array]
  # @changed_instance_variable @upload_cultivars [Array]
  #
  # @calls {ensure_citation}, {BulkUploadDataSet#get_variables_in_heading},
  #   {BulkUploadDataSet#get_upload_sites},
  #   {BulkUploadDataSet#get_upload_entities},
  #   {BulkUploadDataSet#get_upload_species},
  #   {BulkUploadDataSet#get_upload_citations},
  #   {BulkUploadDataSet#get_upload_treatments},
  #   {BulkUploadDataSet#get_upload_cultivars}
  def confirm_data

    begin
      ensure_citation
    rescue => e
      flash[:error] = e.message
      redirect_to(action: "choose_global_citation")
      return
    end

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
      flash.keep # mainly for 'removing citation' message
      redirect_to(action: "choose_global_data_values")
      return
    end

    @data_set = BulkUploadDataSet.new(session)

    if @data_set.trait_data?
      @data_set.get_variables_in_heading # sets @data_set.heading_variable_info

      @variable_to_covariates_mapping = Hash.new
      @data_set.heading_variable_info.each_value do |value|
        @variable_to_covariates_mapping[value[:name]] = value[:covariates].keys
      end
    end

    @upload_sites = @data_set.get_upload_sites
    @upload_entities = @data_set.get_upload_entities
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
  #
  # @calls {ensure_citation}, {BulkUploadDataSet#initialize},
  #   {BulkUploadDataSet#insert_data}
  def insert_data

    begin
      ensure_citation
    rescue => e
      flash[:error] = e.message
      redirect_to(action: "choose_global_citation")
      return
    end

    # This takes care of the case where the user attempts to insert data
    # without ever having submitted the form on the "choose_global_data_values"
    # page:
    if session[:rounding].nil?
    flash.keep # mainly for 'removing citation' message
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

  # not used
  def read_raw_contents
    csvpath = session[:csvpath]
    csv = File.open(csvpath)
    @file_contents = csv.read
    csv.close
  end

  # Ensures there is citation data in the session or in the file but not both.
  #
  # @callers {display_csv_file}, {choose_global_data_values}, {confirm_data},
  #   {insert_data}
  def ensure_citation

    # Remove the linked citation if the file includes citation data:
    if !session[:citation].nil? && session[:file_includes_citation_info]

      flash.now[:warning] = "Removing linked citation since you have citation information in your data set"
      session[:citation] = nil

    elsif session[:citation].nil? && !session[:file_includes_citation_info]

      raise "Please Choose a Citation"

    end

  end


end
