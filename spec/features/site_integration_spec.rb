require 'spec_helper'
include LoginHelper

feature 'Sites index works' do
  before :each do
    login_test_user
  end

  context 'GET /sites' do
    it 'should have "Listing Sites" ' do
      visit '/sites'
      page.should have_content 'Listing Sites'
    end

    it 'should allow creation of new sites' do
      visit '/citations'
      first(:xpath,".//a[contains(@href,'/use_citation/')]").click
      
      visit '/sites/new'
      
      fill_in 'Site name', :with =>'tester'
      fill_in 'Elevation (m)', :with => '2900'
      fill_in 'Mean Annual Precipitation (mm/yr)', :with => '11/90'
      fill_in 'Mean Annual Temperature', :with => '19'
      fill_in 'City', :with => 'Taipei'
      fill_in 'State', :with => 'hungsha'
      select('UNITED STATES', :from => 'Country')
      fill_in 'site_notes', :with => 'working with and manipulating those elements'
      fill_in 'site_soilnotes', :with => 'methods available, so you can restrict them to specific parts of the page'
      click_button 'Create'
      
      page.should have_content 'Site was successfully created'
    end

    context 'clicking view site button' do
      it 'should return "Viewing Site" ' do
        visit '/sites/'
         first(:xpath,".//a[contains(@alt,'show')]").click
        page.should have_content 'Viewing Site'
      end
    end
    
    context 'clicking edit site button' do
      
      before :each do
        visit '/sites/'
        first(:xpath,".//a[ contains(@alt,'edit')]").click
      end

      it 'should return "Editing Site" ' do
        page.should have_content 'Editing Site'
      end

      it 'show allow adding new related citations', js: true do
        click_link 'View Related Citations'
        page.select 'Wood', from: 'citation_id'
        click_button 'Select'
        page.should have_content 'Wood'

      # now do clean-up:
      page.find(:xpath, ".//table/tbody/tr[preceding-sibling::tr/th/text() = 'Auth'][contains(td[3], 'Wood')]/td/a[text() = 'X']").click
      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end
  
    end      

        

    end

    context 'clicking use site button' do
      ## pending
    end

  end
end


