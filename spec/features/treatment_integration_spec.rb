require 'support/helpers'
include LoginHelper

feature 'Treatment features work' do
  before :each do
    login_test_user
  end

  context 'New Treatments' do
    it 'should have a "New Treatment" page' do
      visit '/treatments/new'
      
      expect(page).to have_content 'New Treatment'
    end

    it 'should allow creation of new treatments' do
      visit '/treatments/new'
      fill_in 'Name', :with => 'tester'
      fill_in 'Definition', :with => 'Light utilization anddddd'
      select('True', :from => 'Control')

      click_button 'Create'
      
      expect(page).to have_content 'Treatment was successfully created'
    end
  end

  
  
  context 'Listing Treatments' do
    it 'should return "Listing Treatments" ' do
      visit '/treatments/'

      expect(page).to have_content 'Listing Treatments'
    end

    it 'should return "Listing Treatments" even if a citation has been chosen' do
      visit(citations_path)
      first(:xpath, ".//td[preceding-sibling::td[text() = 'Adler']]/a[contains(@href, 'use_citation')]").click
      visit(treatments_path)
      expect(page).to have_content 'Listing Treatments'
    end
    
  end

  context 'Editing Treatments' do

    before :each do
      visit '/treatments/'
      first(:xpath,".//a[@title='edit' and contains(@href,'/edit')]").click
    end

    it 'following edit link should return content "Editing Treatment" ' do
      expect(page).to have_content 'Editing Treatment'
    end

    it 'should allow adding new related managements', js: true do
        click_link 'View Related Managements'
        page.select 'planting', from: 'management_id'
        click_button 'Select'
        expect(page).to have_content 'planting'

      # now do clean-up:
      page.find(:xpath, ".//table/tbody/tr[preceding-sibling::tr/th/text() = 'Type'][contains(td[last()], 'planting')]/td/a[text() = 'X']").click
      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end
  
    end      

    # This was an attempt to test Github issue #282, but it passes even without the underlying bug being fixed.
    it 'should allow creating new associated managements multiple times', js: true do
      click_link 'Create New Management'
      page.select 'tillage', from: 'management[mgmttype]'
      click_button 'Create'
      click_link 'Create New Management'

      # make another one:
      click_button 'Create'
      click_link 'View Related Managements'

      expect(page.find('div#edit_managements_treatments > table')).to have_xpath('.//table[count(tbody/tr[td]) = 2]')


      # now do clean-up:
      visit '/managements'

      # delete a created management:
      all(:xpath, './/a[@alt = "delete"]')[-1].click
      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end

      sleep 1

      # delete the other one:
      all(:xpath, './/a[@alt = "delete"]')[-1].click
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
      expect(first(:xpath, ".//dt[child::text() = 'Control']/following-sibling::dd[1]").text).to eq "Yes"
    end

    it 'should show a value of "No" for "Control" after we update it' do
      visit '/treatments/1/edit'
      select('False', from: "treatment_control")
      find('form.edit_treatment').find_button('Update').click
      visit '/treatments/1'
      expect(first(:xpath, ".//dt[child::text() = 'Control']/following-sibling::dd[1]").text).to eq "No"
    end
  end

end 
  

