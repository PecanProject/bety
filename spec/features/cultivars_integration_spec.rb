require 'support/helpers'
include LoginHelper

feature 'Cultivars index works' do
  before :each do
    login_test_user
  end

  context 'GET /cultivars' do
    it 'should have "Listing Cultivars" ' do
      visit '/cultivars'
      expect(page).to have_content 'Listing Cultivars'
    end
  end

  context 'GET /cultivars/new', js: true do
    it 'should return "Cultivar was successfully created" ' do
      visit '/cultivars/new'
      
      fill_in 'Name', :with => 'Dingosville'
      fill_in 'Ecotype', :with => 'Boreal'
      fill_in 'Notes', :with => 'Neque porro quisquam est qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit...'
      fill_in 'species_query', :with => 'sacc'
      select('3', :from => 'cultivar[specie_id]')
      click_button 'Create'
      
      expect(page).to have_content 'Cultivar was successfully created'

      # clean-up:
      visit '/cultivars'
      first(:xpath, ".//tr[contains(string(.), 'Dingosville')]//a[@alt = 'delete']").click
      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end
    end
  end
  
  context 'clicking view cultivar button' do
    it 'should return "Viewing Cultivar" ' do
      visit '/cultivars/'
      first(:xpath,".//a[@alt='show' and contains(@href,'/cultivars/')]").click
      expect(page).to have_content 'Viewing Cultivar'
    end
  end
  
  context 'Edit cultivar page' do
    it 'should return "Editing Cultivar" ' do
      visit '/cultivars/'
      first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
      expect(page).to have_content 'Editing Cultivar'
    end
  end
  
  context 'Editing a cultivar' do
    it 'should allow a cultivar to be edited' do
      visit '/cultivars/'
      first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click

      fill_in 'Name', :with => 'Plantesque'
      
      click_button 'Update'
      expect(page).to have_content 'Cultivar was successfully updated.'
    end
    
  end  
  
  
end
