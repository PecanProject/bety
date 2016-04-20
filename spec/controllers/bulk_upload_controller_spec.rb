
describe BulkUploadController, :type => :controller do

  class BulkUploadController
    # override the login requirement for testing:
    before_filter :login_required, only: []
  end

  describe "display csv file" do

    before(:each) do
      get 'start_upload'
    end

    context "test general" do

      it "should display an error when no file has been uploaded" do

        post 'display_csv_file', { 'new upload' => true }
        assert_equal("No file chosen", session[:flash][:error] )
        assert_not_equal(200, response.status) # Since this is a redirect, we should get 302; this test is somewhat redundant in view of the next.
        assert_redirected_to '/bulk_upload/start_upload', "Failed to redirect when no file chosen"
      end

      it "should create a data set when a well-formed CSV file is uploaded" do

        @file = fixture_file_upload("/files/bulk_upload/sample_yields.csv", "text/csv")
        post 'display_csv_file', { 'new upload' => true, "CSV file" => @file }
        assert_not_nil assigns(:data_set)
        assert_instance_of BulkUploadDataSet, assigns(:data_set), "Failed to return dataset instance"
      end


      it "should create a data set when returning to the page if a file was previously uploaded" do

        @file = fixture_file_upload("/files/bulk_upload/sample_yields.csv", "text/csv")
        session[:csvpath] = @file.path
        post 'display_csv_file', { 'new upload' => false }
        assert_not_nil assigns(:data_set)
        assert_instance_of BulkUploadDataSet, assigns(:data_set), "Failed to return dataset instance"
      end

     it "should give an error when returning to the page if the start upload page was visited after a file was uploaded" do

        @file = fixture_file_upload("/files/bulk_upload/sample_yields.csv", "text/csv")
        session[:csvpath] = @file.path
        get 'start_upload'
        post 'display_csv_file', { 'CSV file' => nil }
        assert_equal("No file chosen", session[:flash][:error])
        assert_not_equal(200, response.status)
        assert_redirected_to '/bulk_upload/start_upload', "Failed to redirect when no file chosen"
      end


    end # "test general"

    context "validate data" do

      context "validation of a file with citation data" do

        before(:each) do
          @file = fixture_file_upload("/files/bulk_upload/sample_yields.csv", "text/csv")
          @form = { 'new upload' => true, "CSV file" => @file }
        end

        it "should remove a linked citation when a file is uploaded that includes citation information" do

          session[:citation] = 1
          post 'display_csv_file', @form
          assert_nil session[:citation], "Failed to remove citation from session"
          expect(session[:flash][:warning]).to match(/^Removing/i)
        end

        it "should validate the file data" do

          post 'display_csv_file', @form
          @dataset = assigns(:data_set)
          @validated_data = @dataset.validated_data
          assert_not_nil(@validated_data, "Failed to validate rows")
        end

      end # "validation of a file with citation data"

      context "validation of a file without citation data" do

        before(:each) do

          @file = fixture_file_upload("/files/bulk_upload/sample_yields_with_treatment_but_no_citation.csv", "text/csv")
          @form = { 'new upload' => true, "CSV file" => @file }
        end

        ## These two tests failed because the controller doesn't prevent the user
        ## from entering the url to the next step (though the button isn't shown)
        ## This might not be a real problem, because they are still going to get
        ## some error at the data insertion step if they have a null or wrong citation...
        it "should not allow visiting the 'choose_global_data_values' page without having choosen a citation" do

          post 'display_csv_file', @form
          session[:citation] = nil
          get 'choose_global_data_values'
          assert_not_equal(200, response.status, "Failed to stop when no citation present")

        end

        it "should not allow visiting the 'choose_global_data_values' page when a citation inconsistent with the data set has been chosen" do

          session[:citation] = 4
          post 'display_csv_file', @form
          @dataset = assigns(:data_set)
          # Ensure the citation we set actually *is* inconsistent:
          assert(@dataset.validation_summary.has_key?("Site is inconsistent with citation") && 
                 @dataset.validation_summary["Site is inconsistent with citation"].size > 0,
                 "This citation is actually consistent with the sites given")
          get 'choose_global_data_values'
          assert_not_equal(200, response.status, "Failed to stop when citation is wrong")
        end

      end

      # TODO: possibly test various kinds of invalid files and what messages result
      context "uploading an invalid csv file" do
        it "should throw an error and redirect to the start_upload page" do

          @file = fixture_file_upload("/files/bulk_upload/invalid_file.csv", "text/csv")
          @form = { 'new upload' => true, "CSV file" => @file }
          post 'display_csv_file', @form
          assert_not_nil session[:flash][:error], "Failed to display error message"
          assert_redirected_to '/bulk_upload/start_upload', "Failed to redirect to start upload"
        end
      end

    end # "validate data"

  end # "display_csv_file"

  describe "choose global data values" do
    # actual rounding and data processing not tested here
    before(:each) do
      get 'start_upload'
      @file = fixture_file_upload("/files/bulk_upload/sample_yields.csv", "text/csv")
      @form = { 'new upload' => true, "CSV file" => @file }
      post 'display_csv_file', @form
      get 'choose_global_data_values'
    end

    it "should return a new dataset" do

      assert_not_nil assigns(:data_set)
      assert_instance_of BulkUploadDataSet, assigns(:data_set), "Failed to return dataset"
    end

  end # "choose global data values"


  describe "confirm data" do
    before(:each) do
      get 'start_upload'
      @file = fixture_file_upload("/files/bulk_upload/rounding_demo.csv", "text/csv")
      post 'display_csv_file', { 'new upload' => true, "CSV file" => @file }
      get 'choose_global_data_values'
      @values ={ "global_values" => {}, "rounding" => { "yields" => "2" } }
      request.env["HTTP_REFERER"] = 'choose_global_data_values'
      post 'confirm_data', @values
    end

    it "should return a new dataset" do

      assert_not_nil assigns(:data_set)
      assert_instance_of BulkUploadDataSet, assigns(:data_set), "Failed to return dataset"
    end

    it "should extract summary confirmation data from the dataset" do

      @upload_sites = assigns(:upload_sites)
      assert_equal(1, @upload_sites.size, "Failed to get sites")
      @upload_species = assigns(:upload_species)
      assert_equal(1, @upload_species.size, "Failed to get species")
      @upload_citations = assigns(:upload_citations)
      assert_equal(1, @upload_citations.size, "Failed to get citations")
      @upload_treatments = assigns(:upload_treatments)
      assert_equal(1, @upload_treatments.size, "Failed to get treatments")
      @upload_cultivars = assigns(:upload_cultivars)
      assert_equal(1, @upload_cultivars.size, "Failed to get cultivars")
    end

  end


  describe "insert data" do
    before(:each) do
      @count = Yield.count
      @file = fixture_file_upload("/files/bulk_upload/sample_yields.csv", "text/csv")
      post 'display_csv_file', { 'new upload' => true, "CSV file" => @file }
      get 'choose_global_data_values'
      @values ={ "global_values" => {}, "rounding" => { "yields" => "2" } }
      request.env["HTTP_REFERER"] = 'choose_global_data_values'
      post 'confirm_data', @values
      session[:user_id] = 1 # needed for the insertion step
      post 'insert_data'
    end

    it "should return a new dataset" do

      assert_not_nil assigns(:data_set)
      assert_instance_of BulkUploadDataSet, assigns(:data_set), "Failed to return dataset"
    end

    it "should insert data" do

      @new_count = Yield.count
      assert_equal(1, @new_count - @count, "Failed to insert data")
      assert_not_nil session[:flash][:success]
      assert_redirected_to '/bulk_upload/start_upload'
    end
  end


















end
