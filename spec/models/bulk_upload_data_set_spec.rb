
describe BulkUploadDataSet do

  describe "Minimal requirements for instantiating BulkUploadDataSet" do
    let (:upload_io) {
      Struct.new("Upload", :original_filename, :path)
      path = Proc.new do
        f = File.new("spec/tmp/my_upload_file.csv", "w")
        f.write "yield\n5.1\n"
        f.close
        f.path
      end
      Struct::Upload.new("my_upload_file.csv", path.call)
    }

    it 'uploads' do
      buds = BulkUploadDataSet.new({}, upload_io)
    end
  end

  context "Check header validation works" do

    context "Given a file with the heading 'bogus'" do

      let (:dataset) {
        BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                         'fixtures',
                                                         'files',
                                                         'bulk_upload',
                                                         'heading_validation',
                                                         'bogus_heading.csv') })
      }

      it "we should get a complaint that there is no yield column and no acceptable trait variable column" do
        dataset.check_header_list
        assert(dataset.validation_summary[:field_list_errors].include?('In your CSV file, you must either have a "yield" column or you must have a column that matches the name of acceptable trait variable.'))
      end

      it "we should get a warning that it will ignore column 'bogus'" do
        dataset.check_header_list
        assert_equal(["These columns will be ignored:<br>bogus"], dataset.csv_warnings)
      end

    end

    context "A file with a 'yield' heading" do

      let (:dataset) {
        BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                         'fixtures',
                                                         'files',
                                                         'bulk_upload',
                                                         'sample_yields.csv') })
      }

      it "should be marked as a yield upload file" do
        dataset.check_header_list
        expect(dataset.send(:yield_data?)).to be_truthy
      end

    end

    context "Checks of trait-related heading requirements" do

      context "A file having a recognized trait variable name as a header but no 'yield' heading" do

        let (:dataset) {
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'sample_traits.csv') })
        }

        it "should not produce any errors" do
          dataset.check_header_list
          expect(dataset.validation_summary[:field_list_errors]).to eq([])
        end

        it "should be marked as a trait upload file" do
          dataset.check_header_list
          expect(dataset.send(:trait_data?)).to be_truthy
        end

      end

      context "A file with both a recognized trait variable name as a header and a 'yield' heading" do

        let (:dataset) {
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'ambiguous_data_file.csv') })
        }

        it "should produce an error message" do
          dataset.check_header_list
          expect(dataset.validation_summary[:field_list_errors]).to eq(['If you have a "yield" column, you can not also have column names matching recognized trait variable names.'])
        end

      end

      context "A file with a recognized trait variable name as a heading that has no heading for one of its required covariates" do

        let (:dataset) {
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'missing_required_covariate.csv') })
        }

        it "should produce an error message" do
          dataset.check_header_list
          expect(dataset.validation_summary[:field_list_errors][0]).to match(/These required covariate variable names are not in your heading: .*/)
        end

      end

    end

    context "Given a file with an 'n' column but no 'SE' column" do
     let (:dataset) {
        BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                         'fixtures',
                                                         'files',
                                                         'bulk_upload',
                                                         'heading_validation',
                                                         'n_without_SE.csv') })
      }
      specify "we should get an error message" do
        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq(['If you have an "n" column, you must have an "SE" column as well.'])
      end
    end

    context "Given a file with an 'SE' column but no 'n' column" do
     let (:dataset) {
        BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                         'fixtures',
                                                         'files',
                                                         'bulk_upload',
                                                         'heading_validation',
                                                         'SE_without_n.csv') })
      }
      specify "we should get an error message" do
        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq(['If you have an "SE" column, you must have an "n" column as well.'])
      end
    end

    context "Given a file with a 'citation_doi' column" do

      let (:error_array) {
        ['If you include a "citation_doi" column, then you must not include columns for "citation_author", "citation_title", or "citation_year."']
      }

      specify "we should get an error if there is also a 'citation_author' column" do
        dataset =
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'citation_doi_and_author.csv') })

        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq(error_array)
      end

      specify "we should get an error if there is also a 'citation_year' column" do
        dataset =
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'citation_doi_and_year.csv') })

        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq(error_array)
      end

      specify "we should get an error if there is also a 'citation_title' column" do
        dataset =
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'citation_doi_and_title.csv') })

        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq(error_array)
      end

    end

    context "Given a file with a 'citation_author' column" do
      let (:error_array) {
        ['If you include a "citation_author" column, then you must also include columns for "citation_title" and "citation_year."']
      }
      specify "we should get an error if there is no 'citation_year' column" do
        dataset =
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'citation_author_without_year.csv') })
        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq(error_array)
      end

      specify "we should get an error if there is no 'citation_title' column" do
        dataset =
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'citation_author_without_title.csv') })
        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq(error_array)
      end

    end

    context "Given a file with a 'citation_title' column" do
      specify "we should get an error if there is no 'citation_author' column" do
        dataset =
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'citation_title_without_author.csv') })
        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq(['If you include a "citation_title" column, then you must also include columns for "citation_author" and "citation_year."'])
      end
    end

    context "Given a file with a 'citation_year' column" do
      specify "we should get an error if there is no 'citation_author' or 'citation_title' column" do
        dataset =
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'citation_year_only.csv') })
        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq(['If you include a "citation_year" column, then you must also include columns for "citation_title" and "citation_author."'])
      end
    end

    context "Given a file with a 'citation_doi' column and no other citation columns" do
      dataset =
        BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                         'fixtures',
                                                         'files',
                                                         'bulk_upload',
                                                         'heading_validation',
                                                         'citation_doi_only.csv') })
      specify "the session should have no 'citation_id_list' key set before checking the heading" do
        expect(dataset.instance_variable_get(:@session)[:citation_id_list]).to be_nil
      end

      specify "the session should have a 'citation_id_list' key set after checking the heading" do
        dataset.check_header_list
        expect(dataset.instance_variable_get(:@session)[:citation_id_list]).to eq([])
      end
    end


    context "Given a file with a citation author, year, and title columns but no 'citation_doi' column" do
      specify "the session should have a 'citation_id_list' key set after checking the heading" do
        dataset =
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'citation_author_year_and_title_only.csv') })
        dataset.check_header_list
        expect(dataset.instance_variable_get(:@session)[:citation_id_list]).to eq([])
      end
    end



    context "Given a file with a 'cultivar' column" do
      specify "we should get an error if there is no 'species' column" do
        dataset =
          BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                           'fixtures',
                                                           'files',
                                                           'bulk_upload',
                                                           'heading_validation',
                                                           'cultivar_without_species.csv') })
        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq(['If you have a "cultivar" column, you must have a "species" column as well.'])
      end
    end

    context "Given a file with valid headers that are not in canonical form" do
      dataset =
        BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                         'fixtures',
                                                         'files',
                                                         'bulk_upload',
                                                         'heading_validation',
                                                         'non-canonical_headers.csv') })
      specify "we should get no errors" do
        dataset.check_header_list
        expect(dataset.validation_summary[:field_list_errors]).to eq([])
      end

      specify "we should not get warnings about ignored columns" do
        dataset.check_header_list
        expect(dataset.csv_warnings.grep(/^These columns will be ignored:/)).to be_empty
      end

    end

  end



  context "Given a valid yields data file" do

    let (:dataset) {
      BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                       'fixtures',
                                                       'files',
                                                       'bulk_upload',
                                                       'sample_yields.csv') })
    }

    it 'responds to check_header_list' do
      expect(dataset).to respond_to(:check_header_list)
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
      }.to change { dataset.validated_data.map do |row|
          row.map do |column|
            column[:validation_result] = column[:validation_result].class; column
          end
        end rescue nil }.from(nil).
        to ([
             [
              {:fieldname=>"yield", :data=>"5.5", :validation_result=>Valid},
              {:fieldname=>"citation_author", :data=>"Adams", :validation_result=>Valid},
              {:fieldname=>"citation_year", :data=>"1986", :validation_result=>Valid},
              {:fieldname=>"citation_title", :data=>"Quantum Yields", :validation_result=>Valid},
              {:fieldname=>"site", :data=>"University of Nevada Biological Sciences Center", :validation_result=>Valid},
              {:fieldname=>"species", :data=>"Lolium perenne", :validation_result=>Valid},
              {:fieldname=>"treatment", :data=>"observational", :validation_result=>Valid},
              {:fieldname=>"access_level", :data=>"3", :validation_result=>Valid},
              {:fieldname=>"date", :data=>"1984-07-14", :validation_result=>Valid},
              {:fieldname=>"n", :data=>"5000", :validation_result=>Valid},
              {:fieldname=>"SE", :data=>"1.98", :validation_result=>Valid},
              {:fieldname=>"notes", :data=>"This is bogus yield data.", :validation_result=>Valid},
              {:fieldname=>"cultivar", :data=>"Gremie", :validation_result=>Valid}
             ]
            ])

    end

    it "doesn't change the validation summary when validate_csv_data is run on valid data" do
      dataset.check_header_list
      expect {
        dataset.validate_csv_data
      }.not_to change { dataset.validation_summary }
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
          if function == "get_upload_treatments"
            @get_result.map! { |item| item[:treatment] }
          end
          assert_equal(@expected,@get_result,"Failed to #{function.gsub(/_/,' ')}")
        end
      end
      it "should get upload citations" do
        dataset.check_header_list
        dataset.validate_csv_data
        @session=dataset.instance_eval{@session}
        @expected_citation_list=[]
        @session[:citation_id_list].each do |id|
          @expected_citation_list << Citation.find_by_id(id)
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
        @session.merge!({"rounding"=>{"vars"=>2}})
        @dataset = BulkUploadDataSet.new(@session)
        @insertion_data = @dataset.send("get_insertion_data")
        assert_not_nil @insertion_data, "Failed to get insertion data"
        @expected_data = {
          "access_level"=>"3",
          "date"=>"1984-07-14",
          "dateloc"=>5,
          "n"=>"5000",
          "notes"=>"This is bogus yield data.",
          "citation_id"=>3,
          "site_id"=>2,
          "specie_id"=>18,
          "treatment_id"=>1,
          "cultivar_id"=>417,
          "checked"=>0,
          "user_id"=>1,
          "stat"=>"2",
          "statname"=>"SE",
          "mean"=>"5.5"
        }
        assert_equal(@expected_data,@insertion_data[0],"Insertion data does not match expected")
      end
    end

    context "test rounding" do
      it "should round data to precision" do
        @session = { csvpath: Rails.root.join('spec/fixtures/files/bulk_upload/rounding_demo.csv'), :user_id=>1}
        @dataset = BulkUploadDataSet.new(@session)
        @dataset.check_header_list
        @dataset.validate_csv_data
        @session.merge!({"rounding"=>{"vars"=>2}})
        @dataset = BulkUploadDataSet.new(@session)
        @insertion_data = @dataset.send("get_insertion_data")
        @rounded_yield= @insertion_data[0]["mean"]
        assert_equal(5.9,@rounded_yield.to_f,"Rounded value does not match expected")
      end
    end

  end

  context "Check fuzzy reference finders work" do
    context "Given a row of a data file where the case and whitespace of names and titles don't exactly match existing data" do

      let (:dataset) {
        BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                         'fixtures',
                                                         'files',
                                                         'bulk_upload',
                                                         'data_validation',
                                                         'fuzzily_matching_references.csv') })
      }
      let (:dataset_row) {
        dataset.instance_variable_get(:@data).readlines[0]
      }

      specify "matching of species names is not overly strict" do
        expect(dataset.send("existing_species?", dataset_row["species"])).not_to be_nil
      end

      specify "matching of site names is not overly strict" do
        expect(dataset.send("existing_site?", dataset_row["site"])).not_to be_nil
      end

      specify "matching of treatment names is not overly strict" do
        citation_id = dataset.send("existing_citation", dataset_row["citation_author"],
                                   dataset_row["citation_year"], dataset_row["citation_title"]).id
        expect(dataset.send("existing_treatment?",
                            dataset_row["treatment"],
                            citation_id
                            )).not_to be_nil
      end

      specify "matching of citation titles is not overly strict" do
        expect(dataset.send("existing_citation", dataset_row["citation_author"],
                            dataset_row["citation_year"], dataset_row["citation_title"])).not_to be_nil
      end

      specify "matching of cultivar names is not overly strict" do
        species_id = dataset.send("existing_species?", dataset_row["species"]).id
        expect(dataset.send("existing_cultivar?", dataset_row["cultivar"],
                            species_id)).not_to be_nil
      end

    end

    context "Given validation results on a file where the case and whitespace of names and titles don't exactly match existing data" do
      let (:validation_summary) {
        dataset = BulkUploadDataSet.new({ csvpath: Rails.root.join('spec',
                                                                   'fixtures',
                                                                   'files',
                                                                   'bulk_upload',
                                                                   'data_validation',
                                                                   'fuzzily_matching_references.csv') })
        dataset.check_header_list
        dataset.validate_csv_data
        dataset.validation_summary
      }
      
      specify "should show no inconsistent species references" do
        expect(validation_summary.keys).not_to include(:inconsistent_species_reference)
      end

      specify "should show no inconsistent site references" do
        expect(validation_summary.keys).not_to include(:inconsistent_site_reference)
      end

      specify "should show no inconsistent treatment references" do
        expect(validation_summary.keys).not_to include(:inconsistent_treatment_reference)
      end

      specify "should show no inconsistent citation references" do
        expect(validation_summary.keys).not_to include(:inconsistent_citation_reference)
      end

      specify "should show no inconsistent cultivar references" do
        expect(validation_summary.keys).not_to include(:inconsistent_cultivar_reference)
      end

    end
  end

end
