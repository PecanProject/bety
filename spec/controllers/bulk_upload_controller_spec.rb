require 'spec_helper'

describe BulkUploadController, :type => :controller do
	
	describe "display csv file" do

			before (:each) do
				get 'start_upload'
			end

		context "test general" do 
			
			it "should give error with no file uploaded" do
				post 'display_csv_file', {'new upload' => true}
				assert_equal(session[:flash][:error] , "No file chosen")
				assert_not_equal(response.status, 200)
				assert_redirected_to '/bulk_upload/start_upload', "Failed to redirect when no file chosen"
			end

			it "should create data set with file uploaded" do
				@file = fixture_file_upload("/files/bulk_upload/sample_yields.csv","text/csv") 
				post 'display_csv_file', {'new upload' => true, "CSV file" =>@file}
				assert_not_nil assigns(:data_set)
				assert_instance_of BulkUploadDataSet, assigns(:data_set), "Failed to return dataset instance"
			end
		
		end # "test general"

		context "validate data" do

			context "validate file with citation" do
				
				before(:each) do
					@file = fixture_file_upload("/files/bulk_upload/sample_yields.csv","text/csv") 
					@form ={'new upload' => true, "CSV file" =>@file}
				end

				it "should remove citation" do
					session[:citation] = 1
					post 'display_csv_file', @form
					assert_nil session[:citation], "Failed to remove citation from session"
					session[:flash][:warning].should =~/^[Rmoving]/i
				end

			end # "validate file with citation"

			context "validate file without citation" do

				before(:each) do

					@file = fixture_file_upload("/files/bulk_upload/sample_yields_with_treatment_but_no_citation.csv","text/csv")
					@form = {'new upload' => true, "CSV file" =>@file}
				end

				it "should not proceed without choosing citation" do
					post 'display_csv_file', @form
					session[:citation] = nil
					get 'choose_global_data_values'
					assert_not_equal(response.status, 200 ,"Failed to stop when no citation present")
				end 

				it "should not proceed with wrong citation" do
					post 'display_csv_file', @form
					session[:citaion] = 757
					get 'choose_global_data_values'
					assert_not_equal(response.status, 200 ,"Failed to stop when citation is wrong")
				end

			end
	
		end # "validate data"

	end # "display_csv_file"

end
