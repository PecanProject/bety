require 'spec_helper'
include LoginHelper

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
    end

    specify "doi matching shouldn't be case-sensitive" do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', 'spec/tmp/yield_by_doi.csv'
      click_button 'Upload'
      page.should_not have_content 'Unresolvable citation reference'
    end
  end



  context 'Invalid interactively-specified dates will result in a clearly-specified error' do

    before :all do
      f = File.new("spec/tmp/yield_without_date.csv", "w")
      f.write <<CSV
yield,citation_author,citation_year,citation_title,site,species,treatment,access_level,n,SE,notes,cultivar
5.5,Adams,1986,Quantum Yields,University of Nevada Biological Sciences Center,Lolium perenne,observational,3,5000,1.98,This is bogus yield data.,Gremie
CSV
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
      page.should have_content "Date is in the future"
    end

    specify "A date with only the year and month should result in a clear error message" do
      fill_in 'date', with: '2014-05'
      click_button "Confirm Data"
      page.should have_content "Dates must be in the form 1999-01-01"
    end

    specify "An impossible date should result in a clear error message" do
      fill_in 'date', with: '2014-02-29'
      click_button "Confirm Data"
      page.should have_content "Invalid date"
    end

  end


  context "Given a file with no data" do

    before :all do
      f = File.new("spec/tmp/header_without_data.csv", "w")
      f.write <<CSV
yield
CSV
    end

    # Test for RM issue #2527
    specify 'Files with a header but no data will go to the validation page but result in a clear error message' do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', 'spec/tmp/header_without_data.csv'
      click_button 'Upload'

      first("header").should have_content "Uploaded file: header_without_data.csv"
      first("div.alert").should have_content "No data in file"
    end

  end


    context "Given a file with incomplete data" do

    before :all do
      f = File.new("spec/tmp/file_with_incomplete_data.csv", "w")
      f.write <<CSV
yield,species,site,treatment,date
1.1,Abarema jupunba,University of Nevada Biological Sciences Center,University of Nevada Biological Sciences Center,2002-10-31
CSV
    end

    context "Various scenarios involving attempts to go to pages of the wizard without having uploaded a file" do

      specify 'Attempting to visit the choose_global_citation page without having uploaded a valid file will cause a redirect to the start_upload page' do
        visit '/bulk_upload/choose_global_citation'

        first("header").should have_content "New Bulk Upload"
        first("div.alert").should have_content "No file chosen"
      end

      specify 'Attempting to visit the display_csv_file page without having uploaded a valid file will cause a redirect to the start_upload page' do
        visit '/bulk_upload/display_csv_file'

        first("header").should have_content "New Bulk Upload"
        first("div.alert").should have_content "No file chosen"
      end

      specify 'Attempting to visit the choose_global_data page without having uploaded a valid file will cause a redirect to the start_upload page' do
        visit '/bulk_upload/choose_global_data'

        first("header").should have_content "New Bulk Upload"
        first("div.alert").should have_content "No file chosen"
      end

      specify 'Attempting to visit the confirm_data page without having uploaded a valid file will cause a redirect to the start_upload page' do
        visit '/bulk_upload/confirm_data'

        first("header").should have_content "New Bulk Upload"
        first("div.alert").should have_content "No file chosen"
      end

      specify 'Attempting to run the insert_data action without having uploaded a valid file will cause a redirect to the start_upload page' do
        visit '/bulk_upload/insert_data'

        first("header").should have_content "New Bulk Upload"
        first("div.alert").should have_content "No file chosen"
      end

    end

    context "Various scenarios after uploading the file" do

      before :each do
        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', 'spec/tmp/file_with_incomplete_data.csv'
        click_button 'Upload'
      end

      specify 'Attempting to visit the display_csv_file page without having choosen a citation will cause a redirect to the choose_global_citation page' do
        visit '/bulk_upload/display_csv_file'
        
        first("header").should have_content "Choose a Citation"
      end

      specify 'Attempting to visit the choose_global_data_values page without having choosen a citation will cause a redirect to the choose_global_citation page' do
        visit '/bulk_upload/choose_global_data_values'
        
        first("header").should have_content "Choose a Citation"
      end

      specify 'Attempting to visit the confirm_data page without having choosen a citation will cause a redirect to the choose_global_citation page' do
        visit '/bulk_upload/confirm_data'
        
        first("header").should have_content "Choose a Citation"
      end

      specify 'Attempting to call the insert_data action without having choosen a citation will cause a redirect to the choose_global_citation page' do
        visit '/bulk_upload/insert_data'
        
        first("header").should have_content "Choose a Citation"
      end

    end

    context "Various scenarios after uploading the file and choosing a citation", js: true do

      ### Uncomment this and add 'binding.pry' statements to help in debugging these tests:
      # Capybara.javascript_driver = :selenium

      before :each do
        visit '/bulk_upload/start_upload'
        attach_file 'CSV file', File.join(Rails.root, 'spec/tmp/file_with_incomplete_data.csv') # full path is required if using selenium
        click_button 'Upload'
      end

      specify 'After submitting the citation-choice form, we should see the validation page' do
        ### If we were *only* going to use the Selenium driver, we could do
        ### this.  But capybara-webkit doesn't have a send_keys method.
        # control = page.driver.browser.find_element(:id, 'autocomplete_citation')
        # control.send_keys 'Adler'
        # sleep 1
        # control.send_keys :arrow_down
        # control.send_keys :return

        ### This should work with either Selenium or Capybara-Webkit:
        page.execute_script("jQuery('#autocomplete_citation').val('Adler')")
        sleep 1 # maybe not needed
        page.execute_script("jQuery('#autocomplete_citation').trigger('keydown', {keyCode: 40})")
        sleep 1 # necessary!
        # This doesn't work ...
        #page.execute_script("jQuery('#autocomplete_citation').trigger('keydown', {keyCode: 13})")
        # ... so we have to do this instead:
        first("#ui-id-1").click

        click_button "View Validation Results"

        first("header").should have_content "Uploaded file:"
      end

      specify 'Attempting to visit the choose_global_data_values page without having choosen a citation will cause a redirect to the choose_global_citation page' do
        visit '/bulk_upload/choose_global_data_values'
        
        first("header").should have_content "Choose a Citation"
      end

      specify 'Attempting to visit the confirm_data page without having choosen a citation will cause a redirect to the choose_global_citation page' do
        visit '/bulk_upload/confirm_data'
        
        first("header").should have_content "Choose a Citation"
      end

      specify 'Attempting to call the insert_data action without having choosen a citation will cause a redirect to the choose_global_citation page' do
        visit '/bulk_upload/insert_data'
        
        first("header").should have_content "Choose a Citation"
      end

    end

  end


end
