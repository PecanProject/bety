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

  end

  

end
