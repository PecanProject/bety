require 'spec_helper'
include LoginHelper

feature 'Treatment features work' do
  before :each do
    login_test_user
  end

  context 'New Treatments' do
    it 'should have a "New Treatment" page' do
      visit '/treatments/new'
      
      page.should have_content 'New Treatment'
    end

    it 'should allow creation of new treatments' do
      visit '/treatments/new'
      fill_in 'Name', :with => 'tester'
      fill_in 'Definition', :with => 'Light utilization anddddd'
      select('True', :from => 'Control')

      click_button 'Create'
      
      page.should have_content 'Treatment was successfully created'
    end
  end

  
  
  context 'Listing Treatments' do
    it 'should return "Listing Treatments" ' do
      visit '/treatments/'

      page.should have_content 'Listing Treatments'
    end

    it 'should return "Listing Treatments" even if a citation has been chosen' do
      visit(citations_path)
      first(:xpath, ".//td[preceding-sibling::td[text() = 'Adler']]/a[contains(@href, 'use_citation')]").click
      visit(treatments_path)
      page.should have_content 'Listing Treatments'
    end
    
  end

  context 'Editing Treatments' do

    before :each do
      visit '/treatments/'
      first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
    end

    it 'following edit link should return content "Editing Treatment" ' do
      page.should have_content 'Editing Treatment'
    end

    it 'should allow adding new related managements', js: true do
        click_link 'View Related Managements'
        page.select 'planting', from: 'management_id'
        click_button 'Select'
        page.should have_content 'planting'

      # now do clean-up:
      page.find(:xpath, ".//table/tbody/tr[preceding-sibling::tr/th/text() = 'Type'][contains(td[last()], 'planting')]/td/a[text() = 'X']").click
      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end
  
    end      


  end

  # This tests for the problem mentioned in Redmine issue #1928
  context 'Get /treatments/1' do
    it 'should show a value of "Yes" for "Control"' do
      visit '/treatments/1'
      first(:xpath, ".//dt[child::text() = 'Control']/following-sibling::dd[1]").text.should eq "Yes"
    end

    it 'should show a value of "No" for "Control" after we update it' do
      visit '/treatments/1/edit'
      select('False', from: "treatment_control")
      find('form.edit_treatment').find_button('Create').click
      visit '/treatments/1'
      first(:xpath, ".//dt[child::text() = 'Control']/following-sibling::dd[1]").text.should eq "No"
    end
  end

end 
  

