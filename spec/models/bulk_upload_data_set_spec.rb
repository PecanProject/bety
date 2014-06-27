require 'spec_helper'

describe BulkUploadDataSet do

  let (:upload_io) {
    Struct.new("Upload", :original_filename, :read)
    Struct::Upload.new("my_upload_file.csv", "yield\n5.1\n")
  }

  it 'uploads' do
    buds = BulkUploadDataSet.new({}, upload_io)
  end
  
  let (:dataset) { 
    BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                     'fixtures', 
                                                     'files',
                                                     'bulk_upload',
                                                     'sample_yields.csv') })
  }

  it 'responds to check_header_list' do
    dataset.should respond_to(:check_header_list)
  end

  it 'updates the validation summary when check_header_list is run' do
    expect {
      dataset.check_header_list
    }.to change { dataset.validation_summary }.from(nil).to({ field_list_errors: [] })
  end

  it 'initializes validated_data when validate_csv_data is run' do
    dataset.check_header_list
=begin
dataset.validate_csv_data
puts dataset.validated_data
dataset.validated_data = nil
=end
    expect {
      dataset.validate_csv_data
    }.to change { dataset.validated_data }.from(nil).
      to (
          [
           [
            {:fieldname=>"yield", :data=>"5.5", :validation_result=>:valid},
            {:fieldname=>"citation_author", :data=>"Adams", :validation_result=>:valid},
            {:fieldname=>"citation_year", :data=>"1986", :validation_result=>:valid},
            {:fieldname=>"citation_title", :data=>"Quantum Yields", :validation_result=>:valid},
            {:fieldname=>"site", :data=>"University of Nevada Biological Sciences Center", :validation_result=>:valid},
            {:fieldname=>"species", :data=>"Lolium perenne", :validation_result=>:valid},
            {:fieldname=>"treatment", :data=>"observational", :validation_result=>:valid, :validation_message=>"This column will be ignored."},
            {:fieldname=>"access_level", :data=>"3", :validation_result=>:valid},
            {:fieldname=>"date", :data=>"1984-07-14", :validation_result=>:valid},
            {:fieldname=>"n", :data=>"5000", :validation_result=>:valid},
            {:fieldname=>"SE", :data=>"1.98", :validation_result=>:valid},
            {:fieldname=>"notes", :data=>"This is bogus yield data."},
            {:fieldname=>"cultivars", :data=>"Gremie", :validation_result=>:ignored, :validation_message=>"This column will be ignored."}
           ]
          ]
          )

  end

  it "doesn't change the validation summary when validate_csv_data is run on valid data" do
    dataset.check_header_list
    expect {
      dataset.validate_csv_data
    }.not_to change { dataset.validation_summary }.from({ field_list_errors: [] })
      .to ({:field_list_errors=>[]})
  end

  # tests for the get_upload_* methods
  # avoiding hard coded values so it could be used on different input files
  context "get upload data" do 
    @methods=["get_upload_sites","get_upload_species","get_upload_treatments"]
    before(:all) do
      @field=["site","species","treatment"]
      @models=[Site,Specie,Treatment]
      @by=["sitename","scientificname","name"]
    end
    @methods.each_with_index do |function,i|
      it "should #{function.gsub(/_/,' ')}" do
        @csv_data=dataset.instance_eval{@data}
        # get expected data from the original csv file
        @expected=[]
        @csv_data.each do |row|
          @param=row[@field[i]]
          @expected << @models[i].send("find_by_#{@by[i]}",@param)
        end
        # get result returned by the function
        @get_result = dataset.send(function)          
        assert_equal(@expected,@get_result,"Failed to #{function.gsub(/_/,' ')}")
      end
    end
    it "should get upload citations" do
      dataset.check_header_list
      dataset.validate_csv_data
      @session=dataset.instance_eval{@session}
      @expected_citation_list=[]
      @session[:citation_id_list].each do |id|
        @expected_citation_list <<Citation.find_by_id(id)
      end
      @get_result = dataset.get_upload_citations
      assert_equal(@expected_citation_list,@get_result,"Failed to get upload citations")
    end     
  end
  
  context "insert data" do 
    it "should get insertion data"do 
      @session = { csvpath: Rails.root.join('spec/fixtures/files/bulk_upload/sample_yields.csv'), :user_id=>1}
      @dataset = BulkUploadDataSet.new(@session)
      @dataset.check_header_list
      @dataset.validate_csv_data
      @session.merge!({"rounding"=>{"yields"=>2}})
      @dataset = BulkUploadDataSet.new(@session)
      @insertion_data = @dataset.get_insertion_data
      assert_not_nil @insertion_data, "Failed to get insertion data"
      @expected_data = {
        "access_level"=>"3", 
        "date"=>"1984-07-14", "n"=>"5000", 
        "notes"=>"This is bogus yield data.", 
        "citation_id"=>3, "site_id"=>2, "specie_id"=>18, 
        "treatment_id"=>1, "checked"=>0, 
        "user_id"=>1, 
        "mean"=>"5.5", 
        "stat"=>"2", 
        "statname"=>"SE"
      }
     assert_equal(@insertion_data[0],@expected_data,"Insertion data does not match expected")

    end
  end

  
end
