require 'support/helpers'
include LoginHelper
include BulkUploadHelper

feature 'Bulk Data Upload' do
  before :each do
    login_test_user
  end




  context 'Non-strictly matching DOI is OK' do

    before :all do
      f = File.new("spec/tmp/yield_by_doi.csv", "w")
      f.write <<CSV
yield,citation_doi
4.23,10.2134/AGRONJ2005.0351
CSV
      f.close
    end

    after :all do
      File::delete("spec/tmp/yield_by_doi.csv")
    end

    specify "doi matching shouldn't be case-sensitive" do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', 'spec/tmp/yield_by_doi.csv'
      click_button 'Upload'
      expect(page).not_to have_content 'Unresolvable citation reference'
    end
  end



  context 'Invalid interactively-specified dates will result in a clearly-specified error' do

    before :all do
      f = File.new("spec/tmp/yield_without_date.csv", "w")
      f.write <<CSV
yield,citation_author,citation_year,citation_title,site,species,treatment,access_level,n,SE,notes,cultivar
5.5,Adams,1986,Quantum Yields,University of Nevada Biological Sciences Center,Lolium perenne,observational,3,5000,1.98,This is bogus yield data.,Gremie
CSV
      f.close
    end

    after :all do
      File::delete("spec/tmp/yield_without_date.csv")
    end

    before :each do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', 'spec/tmp/yield_without_date.csv'
      click_button 'Upload'
      click_link 'Specify'
    end

    specify "A date in the future should result in a clear error message" do
      fill_in 'date', with: '2500-07-11'
      click_button "Confirm Data"
      expect(page).to have_content "Date is in the future"
    end

    specify "A date with only the year and month should result in a clear error message" do
      fill_in 'date', with: '2014-05'
      click_button "Confirm Data"
      expect(page).to have_content "Dates must be in the form 1999-01-01"
    end

    specify "An impossible date should result in a clear error message" do
      fill_in 'date', with: '2014-02-29'
      click_button "Confirm Data"
      expect(page).to have_content "Invalid date"
    end

  end


  context "Given a file with no data" do

    before :all do
      f = File.new("spec/tmp/header_without_data.csv", "w")
      f.write <<CSV
yield
CSV
      f.close
    end

    after :all do
      File::delete("spec/tmp/header_without_data.csv")
    end

    # Test for RM issue #2527
    specify 'Files with a header but no data will go to the validation page but result in a clear error message', js: true do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/header_without_data.csv')
      click_button 'Upload'

      choose_citation_from_dropdown

      expect(first("header")).to have_content "Uploaded file: header_without_data.csv"
      expect(current_path).to match(/display_csv_file/)
      expect(first("div.alert")).to have_content "No data in file"
    end

  end


  # Tests for RM issue #2525 (item 1 of update #2):
  context "Various scenarios involving attempts to go to pages of the wizard without having uploaded a file" do

    specify 'Attempting to visit the choose_global_citation page without having uploaded a CSV file will cause a redirect to the start_upload page' do
      visit '/bulk_upload/choose_global_citation'

      expect(first("header")).to have_content "New Bulk Upload"
      expect(first("div.alert")).to have_content "No file chosen"
    end

    specify 'Attempting to visit the display_csv_file page without having uploaded a CSV file will cause a redirect to the start_upload page' do
      visit '/bulk_upload/display_csv_file'

      expect(first("header")).to have_content "New Bulk Upload"
      expect(first("div.alert")).to have_content "No file chosen"
    end

    specify 'Attempting to visit the choose_global_data_values page without having uploaded a CSV file will cause a redirect to the start_upload page' do
      visit '/bulk_upload/choose_global_data_values'

      expect(first("header")).to have_content "New Bulk Upload"
      expect(first("div.alert")).to have_content "No file chosen"
    end

    specify 'Attempting to visit the confirm_data page without having uploaded a CSV file will cause a redirect to the start_upload page' do
      visit '/bulk_upload/confirm_data'

      expect(first("header")).to have_content "New Bulk Upload"
      expect(first("div.alert")).to have_content "No file chosen"
    end

  end


  context "Various scenarios involving the case where the citation is not specified in the upload file" do

    before :all do
      f = File.new("spec/tmp/file_without_citation_info.csv", "w")
      f.write <<CSV
yield,species,site,treatment,date
1.1,Abarema jupunba,University of Nevada Biological Sciences Center,observational,2002-10-31
CSV
      f.close
    end

    after :all do
      File::delete("spec/tmp/file_without_citation_info.csv")
    end

    before :each do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_without_citation_info.csv')
      click_button 'Upload'
    end

    # Tests for RM issue #2525 (item 2 of update #2):
    context "Various scenarios involving attempts to go to pages of the wizard without having chosen a citation" do

      specify 'Attempting to visit the display_csv_file page without having choosen a citation will cause a redirect to the choose_global_citation page' do
        visit '/bulk_upload/display_csv_file'

        expect(first("header")).to have_content "Choose a Citation"
      end

      specify 'Attempting to visit the choose_global_data_values page without having choosen a citation will cause a redirect to the choose_global_citation page' do
        visit '/bulk_upload/choose_global_data_values'

        expect(first("header")).to have_content "Choose a Citation"
      end

      specify 'Attempting to visit the confirm_data page without having choosen a citation will cause a redirect to the choose_global_citation page' do
        visit '/bulk_upload/confirm_data'

        expect(first("header")).to have_content "Choose a Citation"
      end

    end

    # Tests related to RM issue #2602
    context "Scenario involving changing the interactively-chosen citation" do

      specify "Changing the citation outside of the bulk-upload wizard should require re-validation of the data file", js: true do
        choose_citation_from_dropdown 'Adams'
        click_link 'Specify Dataset-wide values'
        select 'Public', from: 'access_level'
        click_button 'Confirm Data'
        visit '/citations'
        first(:xpath, ".//tr[contains(td, 'Adler')]/td/a[@alt = 'use']").click
        click_link 'Bulk Upload'
        expect(current_path).to match(/display_csv_file/)
      end

    end

    # Test for RM issue #2603
    context "Submitting a blank global citation form", js: true do

      before :each do
        choose_citation_from_dropdown
        click_link "Choose a different citation"
        click_button "View Validation Results"
      end

      specify "should not result in a warning message" do
        expect(page).to_not have_selector('div.alert-warning')
      end

      specify "should keep the previously-chosen citation" do
        expect(page.find('h5')).to have_content("Citation: Adler")
      end

    end

  end

  # Tests for RM issue #2525 (item 3 of update #2):
  context "Various scenarios after uploading an invalid file that included citation information" do

    before :all do
      f = File.new("spec/tmp/file_with_invalid_data.csv", "w")
      f.write <<CSV
yield,citation_doi,species,site,treatment,date
1.1,10.2134/AGRONJ2005.0351,Sweet Woodruff,University of Nevada Biological Sciences Center,University of Nevada Biological Sciences Center,2002-10-31
CSV
      f.close
    end

    after :all do
      File::delete("spec/tmp/file_with_invalid_data.csv")
    end

    before :each do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_with_invalid_data.csv') # full path is required if using selenium
      click_button 'Upload'
    end


    specify 'After submitting the file, we should see the validation page' do
      expect(first("header")).to have_content "Uploaded file:"
      expect(current_path).to match(/display_csv_file/)
    end

    specify 'Attempting to visit the choose_global_data_values page without having a valid file will cause a redirect to the display_csv_file page' do
      visit '/bulk_upload/choose_global_data_values'

      expect(page).to have_content "Data Value Errors"
    end

    specify 'Attempting to visit the confirm_data page without having choosen a citation will cause a redirect to the display_csv_file page' do
      visit '/bulk_upload/confirm_data'

      expect(page).to have_content "Data Value Errors"
    end

  end

  # Tests for RM issue #2525 (item 4 of update #2):
  context "Various scenarios involving failure to provide some data interactively" do

    before :all do
      f = File.new("spec/tmp/file_with_incomplete_data.csv", "w")
      f.write <<CSV
yield,citation_author,citation_year,citation_title,site,treatment,date
1.1,Adams,1986,Quantum Yields of CAM Plants Measured by Photosynthetic O2 Exchange,University of Nevada Biological Sciences Center,observational,2002-10-31
CSV
      f.close
    end

    after :all do
      File::delete("spec/tmp/file_with_incomplete_data.csv")
    end

    before :each do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_with_incomplete_data.csv') # full path is required if using selenium
      click_button 'Upload'
    end

    specify 'Attempting to visit the confirm_data page without having specified missing information will cause a redirect to the choose_global_data_values page' do
      visit '/bulk_upload/confirm_data'

      expect(first("header")).to have_content "Specify Upload Options and Global Values"
    end

  end

  context "Various scenarios involving a file that requires no interactively-specified additional data" do

    before :all do
      f = File.new("spec/tmp/file_with_complete_data.csv", "w")
      f.write <<CSV
yield,citation_author,citation_year,citation_title,site,treatment,date,species,access_level
1.1,Adams,1986,Quantum Yields of CAM Plants Measured by Photosynthetic O2 Exchange,University of Nevada Biological Sciences Center,observational,2002-10-31,Lolium perenne,1
CSV
      f.close
    end

    after :all do
      File::delete("spec/tmp/file_with_complete_data.csv")
    end

    # Test for RM issue #2526
    specify "A cultivar entry box should not appear on the choose_global_data_values page" do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_with_complete_data.csv') # full path is required if using selenium
      click_button 'Upload'
      click_link 'Specify'
      expect(page.document.find('.content')).not_to have_content("cultivar")
    end

    context "A citation has been selected but rounding has not been specified" do

      before :each do
        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_with_complete_data.csv') # full path is required if using selenium
        click_button 'Upload'
        visit '/citations'
        first(:xpath, '//a[@alt = "use"]').click

        expect(page).to have_content "Citation: "
      end

      specify 'If you have a session citation and then visit the display_csv_file page, the session citation should be removed.' do
        visit '/bulk_upload/display_csv_file'

        expect(first("header")).to have_content "Uploaded file:"
        expect(current_path).to match(/display_csv_file/)
        expect(first("div.alert")).to have_content "Removing linked citation since you have citation information in your data set"
      end

      specify 'If you have a session citation and then visit the choose_global_data_values page, the session citation should be removed.' do
        visit '/bulk_upload/choose_global_data_values'

        expect(first("header")).to have_content "Specify Upload Options and Global Values"
        expect(first("div.alert")).to have_content "Removing linked citation since you have citation information in your data set"
      end

      specify 'If you have a session citation and then visit the confirm_data page, the session citation should be removed' +
        "\n        and if you have not specified the amount of rounding, you should be returned to the \"choose global values\" page." do

        visit '/bulk_upload/confirm_data'
        expect(page).not_to have_content "Citation: "
        expect(first("div.alert")).to have_content "Removing linked citation since you have citation information in your data set"
        expect(first("header")).to have_content "Specify Upload Options and Global Value"

      end

    end # context "A citation has been selected but rounding has not been specified"


    context "A citation has been selected and rounding has been specified" do

      before :each do
        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_with_complete_data.csv') # full path is required if using selenium
        click_button 'Upload'
        click_link 'Specify'
        click_button 'Confirm'

        visit '/citations'
        first(:xpath, '//a[@alt = "use"]').click

        expect(page).to have_content "Citation: "
      end

      specify 'If you have a session citation and then visit the confirm_data page, the session citation should be removed' +
        "\n        and if you have specified the amount of rounding, you should be returned to the \"confirm data\" page." do
        visit '/bulk_upload/confirm_data'

        expect(first("header")).to have_content "Verify Upload Specifications and Data-Set References"
        expect(page).not_to have_content "Citation: "
        expect(first("div.alert")).to have_content "Removing linked citation since you have citation information in your data set"
      end

      specify 'If you have a session citation and then visit the insert_data action, the session citation should be removed' +
        "\n        and if you have specified the amount of rounding, you should be returned to the \"confirm data\" page" do
        visit '/bulk_upload/confirm_data'

        expect(first("header")).to have_content "Verify Upload Specifications and Data-Set References"
        expect(page).not_to have_content "Citation: "
        expect(first("div.alert")).to have_content "Removing linked citation since you have citation information in your data set"
      end

    end # context "A citation has been selected and rounding has been specified"

  end # context "Various scenarios involving a file that requires no interactively-specified additional data"

  context "Various scenarios involving the variable names in the heading of a trait upload file" do

    # Tests related to Redmine task #2556
    context "A file with some missing optional covariate values has been uploaded" do

      before :all do
        f = File.new("spec/tmp/file_with_missing_covariate_values.csv", "w")
        f.write <<CSV
SLA,canopy_layer,citation_author,citation_year,citation_title,site,treatment,date,species,access_level
550,3,Adams,1986,Quantum Yields of CAM Plants Measured by Photosynthetic O2 Exchange,University of Nevada Biological Sciences Center,observational,2002-10-31,Lolium perenne,1
540,,Adams,1986,Quantum Yields of CAM Plants Measured by Photosynthetic O2 Exchange,University of Nevada Biological Sciences Center,observational,2002-10-31,Lolium perenne,1
460,2,Adams,1986,Quantum Yields of CAM Plants Measured by Photosynthetic O2 Exchange,University of Nevada Biological Sciences Center,observational,2002-10-31,Lolium perenne,1
440,,Adams,1986,Quantum Yields of CAM Plants Measured by Photosynthetic O2 Exchange,University of Nevada Biological Sciences Center,observational,2002-10-31,Lolium perenne,1
CSV
        f.close
      end

      after :all do
        File::delete("spec/tmp/file_with_missing_covariate_values.csv")
      end

      it "should pass validation", js: true do
        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_with_missing_covariate_values.csv')
        click_button 'Upload'

        expect(first("header")).to have_content "Uploaded file: file_with_missing_covariate_values.csv"
        expect(current_path).to match(/display_csv_file/)
        expect(page.body).not_to have_selector '#error_explanation'
      end

      it "should only insert two new covariate rows", js: true do

        start_size = Covariate.all.size

        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_with_missing_covariate_values.csv')
        click_button 'Upload'
        click_link 'Specify'
        click_button "Confirm"
        click_button "Insert"

        sleep 1 # give time for insertion to complete
        end_size = Covariate.all.size

        # clean up:

        time_limit = page.driver.is_a?(Capybara::Selenium::Driver) ? 90 # allow longer for Selenium driver
                     : 30 # than for WebKit
        begin
          # Wrap while loops in timeout in case some deletion fails
          Timeout.timeout time_limit do

            # Remove covariates before traits because they refer to traits:
            visit '/covariates'
            # This relies on the covariates being sorted by id and the fact that the
            # added covariates are assigned higher ids than the fixture covariates:
            while all(:xpath, "//tbody/tr").size > start_size
              # delete all covariates except the first
              first(:xpath, "//tbody/tr[count(preceding-sibling::tr) >= #{start_size}]//a[@alt = 'delete']").click
              # If we're using Selenium, we have to deal with the modal dialogue:
              if page.driver.is_a? Capybara::Selenium::Driver
                a = page.driver.browser.switch_to.alert
                a.accept
              end
              sleep 1
            end

            # Removed traits before entities because they refer to entities:
            visit '/traits'
            # This relies on the fixtures setting the "checked" attribute to "passed" for them not to be deleted:
            while all(:xpath, "//tbody/tr[not(td/select/option[@selected = 'selected']/text() = 'passed')]").size > 0
              # delete all covariates except the first
              first(:xpath, "//tbody/tr[not(td/select/option[@selected = 'selected']/text() = 'passed')]//a[@alt = 'delete']").click
              # If we're using Selenium, we have to deal with the modal dialogue:
              if page.driver.is_a? Capybara::Selenium::Driver
                a = page.driver.browser.switch_to.alert
                a.accept
              end
              sleep 1
            end

            visit '/entities'
            # This relies on the fixures setting the "notes" attribute to "keepme" as a marker not to delete them:
            while all(:xpath, "//tbody/tr[not(td/text() = 'keepme')]").size > 0
              # delete all covariates except the first
              first(:xpath, "//tbody/tr[not(td/text() = 'keepme')]//a[@alt = 'delete']").click
              # If we're using Selenium, we have to deal with the modal dialogue:
              if page.driver.is_a? Capybara::Selenium::Driver
                a = page.driver.browser.switch_to.alert
                a.accept
              end
              sleep 1
            end

          end # timeout

        rescue Timeout::Error => e

          raise "Clean-up stage timed out; reload fixture to clean up manually"

        end # begin/rescue block

        expect(end_size - start_size).to eq(2)

      end

    end # context "A file with some missing covariate values has been uploaded"

    describe "How parsing of variables in the heading works" do

      specify "A variable in the heading should be recognized even if it isn't in the trait_covariate_associations table" do
        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', Rails.root.join('spec',
                                                'fixtures',
                                                'files',
                                                'bulk_upload',
                                                'trait_variables_in_heading',
                                                'valid-test-data-with-traits-not-in-associations-table.csv')
        click_button 'Upload'
        expect(page).not_to have_content('error')
        click_link 'Specify'
        click_button 'Confirm'
        expect {
          click_button 'Insert Data'
          # Use this instead of sleep():
          expect(first("div.alert-success")).to have_content("Data from valid-test-data-with-traits-not-in-associations-table.csv was successfully uploaded.")
        }.to change { Trait.count }.by(2)
               .and change { Covariate.count }.by(0)
                      .and change { Entity.count }.by 1;     # The two rows in the file have the same entity name.
      end

      specify "If there is a covariate variable in the heading without there being a corresponding trait variable, the CSV file is invalid" do
        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', Rails.root.join('spec',
                                                'fixtures',
                                                'files',
                                                'bulk_upload',
                                                'trait_variables_in_heading',
                                                'test-data-with-invalid-extraneous-covariate.csv')
        click_button 'Upload'
        expect(page).to have_content('error')
      end

      specify "Heading variables that are in the trait_covariate_associations table should be recognized as usual" do
        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', Rails.root.join('spec',
                                                'fixtures',
                                                'files',
                                                'bulk_upload',
                                                'trait_variables_in_heading',
                                                'valid-test-data.csv')
        click_button 'Upload'
        expect(page).not_to have_content('error')
        click_link 'Specify'
        click_button 'Confirm'
        expect { click_button 'Insert Data' }.to change { Trait.count }.by(2)
                                             .and change { Covariate.count }.by(2)
                                             .and change { Entity.count }.by 1;     # The two rows in the file have the same entity name.
        expect(first("div.alert-success")).to have_content("Data from valid-test-data.csv was successfully uploaded.")
      end

    end # describe "How parsing of variables in the heading works"

  end # context "Various scenarios involving the variable names in the heading of a trait upload file"


  context "Tests of notes column functionality" do
    before :each do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', Rails.root.join('spec',
                                              'fixtures',
                                              'files',
                                              'bulk_upload',
                                              'blank_cells_in_notes_column.csv')
      click_button 'Upload'
      click_link 'Specify'
      click_button 'Confirm'
    end

    # GitHub issue #485
    specify "A CSV file with a notes column should be able to leave cells in that column blank" do
      expect { click_button 'Insert Data' }.to  change { Trait.count }.by(2)
                                           .and change { Covariate.count }.by(2)
                                           .and change { Entity.count }.by(1);  # The two rows in the file have the same entity name.
      expect(first("div.alert-success")).to have_content("Data from blank_cells_in_notes_column.csv was successfully uploaded.")
    end

    # GitHub issue #533
    # (The "fix" for issue $485 introduced this bug: all notes were being set to the empty string.)
    specify "Non-empty notes values in a CSV file should be inserted into the database" do
      click_button 'Insert Data'
      query =<<-QUERY
          SELECT t.notes FROM traits t JOIN variables v ON v.id = t.variable_id
              JOIN sites s ON s.id = t.site_id
              WHERE t.created_at > utc_now() - INTERVAL '2 seconds'
              AND v.name = 'SLA'
              AND s.sitename = 'University of Nevada Biological Sciences Center'
      QUERY
      expect(Trait.connection.exec_query(query).first["notes"]).to eq("This was from a western site")
    end

  end

  # GitHub issue #452
  specify "A file with an unmatched citation shouldn't yield a complaint about undefined method `empty?'" do
    visit '/bulk_upload/start_upload'
    attach_file 'CSV file', Rails.root.join('spec',
                                            'fixtures',
                                            'files',
                                            'bulk_upload',
                                            'data_validation',
                                            'unmatched_citation_and_global_treatment.csv')
    click_button 'Upload'
    expect(page).not_to have_content('undefined method')
  end


  # GitHub issue #545
  context "Tests for date support" do

    context "Testing 'date-only' values" do
      
      before :all do
        f = File.new("spec/tmp/file_with_missing_covariate_values.csv", "w")
        f.write <<CSV
SLA,canopy_layer,citation_author,citation_year,citation_title,site,treatment,date,species,access_level,method
550,3,Adams,1986,Quantum Yields of CAM Plants Measured by Photosynthetic O2 Exchange,University of Nevada Biological Sciences Center,observational,2002-10-31,Lolium perenne,1,test
CSV
        f.close
      end

      after :all do
        File::delete("spec/tmp/file_with_missing_covariate_values.csv")
      end

      # This tests a long-standing bug whereby the date value inserted
      # is the UTC time corresponding to midnight in Urbana on the
      # date given in the CSV file.  It should be the value
      # corresponding to midnight site time (if a site having a stored
      # time zone is given).
      specify "The date inserted into the database should be the UTC time corresponding to 12am site time on the date specified" do
        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_with_missing_covariate_values.csv')
        click_button 'Upload'
        click_link 'Specify'
        click_button 'Confirm'
        click_button 'Insert Data'
        
        query =<<-QUERY
        SELECT extract(HOUR FROM site_or_utc_date(date, effective_time_zone(site_id))) AS hour
            FROM traits WHERE created_at > utc_now() - INTERVAL '2 seconds'
      QUERY
        expect(Trait.connection.exec_query(query).first['hour'].to_i).to eq(0)
      end

    end


    context "Testing 'date-with-time-of-day' values" do
      
      before :all do
        f = File.new("spec/tmp/file_with_missing_covariate_values.csv", "w")
        f.write <<CSV
SLA,canopy_layer,citation_author,citation_year,citation_title,site,treatment,date,species,access_level,method
550,3,Adams,1986,Quantum Yields of CAM Plants Measured by Photosynthetic O2 Exchange,University of Nevada Biological Sciences Center,observational,2002-10-31T14:30:24,Lolium perenne,1,test
CSV
        f.close
      end

      after :all do
        File::delete("spec/tmp/file_with_missing_covariate_values.csv")
      end

      # This tests that dates of the form "YYYY-MM-DDTHH:MM:SS" will not result in an error.
      specify "Giving a date that includes the time of day will not result in an error" do
        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_with_missing_covariate_values.csv')
        click_button 'Upload'

        expect(page).not_to have_content "Error"
      end

    end

  end
    
end
