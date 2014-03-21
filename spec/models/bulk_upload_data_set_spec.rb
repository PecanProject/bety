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
  
end
