require 'spec_helper'
include LoginHelper

feature 'CSV file upload works' do
  before :each do
    login_test_user
  end


  context 'GET /bulk_upload/start_upload' do

    it 'should upload the given file' do

      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', Rails.root.join('spec',
                                              'fixtures', 
                                              'files',
                                              'bulk_upload',
                                              'sample_yields.csv')
      click_button 'Upload'
      page.should have_content 'Uploaded file: sample_yields.csv'
    end


    it 'should not give an error when the citation chosen interactively but treatment is not' do
      visit '/bulk_upload/start_upload'
      attach_file 'CSV file', Rails.root.join('spec',
                                              'fixtures', 
                                              'files',
                                              'bulk_upload',
                                              'sample_yields_with_treatment_but_no_citation.csv')
      click_button 'Upload'
      click_link 'Select a Citation'
      first(:xpath, ".//td[text() = 'Adams']/ancestor::tr/td[8]/a[1]").click
      click_link 'Bulk Upload'
      page.should_not have_content 'Select a Citation'
      page.should have_content 'Specify '
      click_link 'Specify'
      click_button 'Confirm'
      page.should have_content 'Please Verify Data-Set References Before Uploading'
      click_button 'Insert Data'
      page.should_not have_selector('.alert-error')
    end      


  end
end
