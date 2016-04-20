require 'support/helpers'
include LoginHelper

feature 'Yields pages work' do

  context 'Logged on as Administrator' do
    before :each do
      login_test_user
    end

#    it 'should have "Listing Yields" ' do
#      visit '/yields'
#      page.should have_content 'Listing Yields'
#    end

    it 'should forward to citations index when clicking "New Yield" ' do
      visit '/yields'
      click_link 'New Yield'
      
      expect(page).to have_content 'Choose a citation to work with ( Actions Tab > Check )'
      expect(page).to have_content 'Listing Citations'
    end

    it 'should allow creation of new yields after selecting a citation', :js => true do
      visit '/citations'
      first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/')]").click

      visit '/yields/new'
      
      select('SD', :from => 'yield[statname]')
      fill_in 'yield[mean]', :with => '10.0'
      fill_in 'yield[stat]', :with => '98736.0'
      fill_in 'yield[n]', :with =>  '100'
      fill_in 'Notes', :with =>  'In some technical publications, appendices are so long and important as part of the book that they are a creative endeavour of the author'
      select('10', :from => 'yield[date(3i)]')
      select('10', :from => 'yield[date(2i)]')
      select('1800', :from => 'yield[date(1i)]')

      fill_in 'species_query', :with => 'sacc'
      select('3', :from => 'yield[specie_id]')

      click_button 'Create'
      
      expect(page).to have_content 'Yield was successfully created.'

      # now do clean-up:
      visit '/yields?search=sacc'
      first(:xpath, "//a[@alt = 'delete']").click
      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end
    end
    
    it 'should not allow creation of new yields without a numeric mean', :js => true do
      visit '/citations'
      first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/')]").click

      visit '/yields/new'
      fill_in 'yield[mean]', :with => 'asdf'
      fill_in 'yield[stat]', :with => '98736.0'
      select('1', :from => 'yield[date(3i)]')
      select('1 - January', :from => 'yield[date(2i)]')
      select('1800', :from => 'yield[date(1i)]')

      fill_in 'species_query', :with => 'sacc'
      select('3', :from => 'yield[specie_id]')

      click_button 'Create'
      
      expect(page).to have_content 'Mean is not a number'
    end

    specify "Managers should be allowed to delete yields, even those they didn't create", js: true do
      visit '/citations'
      first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/')]").click

      visit '/yields/new'

      # Required attributes:
      fill_in 'yield[mean]', :with => '10.0'
      select('10', :from => 'yield[date(3i)]')
      select('10', :from => 'yield[date(2i)]')
      select('1800', :from => 'yield[date(1i)]')
      fill_in 'species_query', :with => 'Abar'
      select('2', :from => 'yield[specie_id]')

      # Change from default (1) so Manager can see this record:
      select('4', from: 'yield[access_level]')
      click_button 'Create'

      # log out and log back in as a Manager:
      click_link 'Logout'
      login_nonadmin_test_user # Manager

      # Now try to go and delete the record just created:
      visit '/yields'

      ## Having multiple expectations in this test will help pinpoint exactly
      ## where the error occurs (if it does occur):
      expect(page).to have_xpath(".//tr/td/a[text() = 'Abarema jupunba']")
      expect(page).to have_xpath(".//tr[td/a/text() = 'Abarema jupunba']/td/a[@alt = 'delete']")

      first(:xpath, ".//tr[td/a/text() = 'Abarema jupunba']/td/a[@alt = 'delete']").click
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end

      expect(page).not_to have_content 'Abarema jupunba'
    end

    context 'clicking view yield button' do
      it 'should return "Viewing Yield" ' do
        visit '/yields/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/yields/')]").click
        expect(page).to have_content 'Viewing Yield'
      end
    end
    
    context 'clicking edit yield button' do
      it 'should return "Editing Yield" ' do
        visit '/yields/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        expect(page).to have_content 'Editing Yield'
      end
    end

    context 'editing a yield without having chosen a citation' do
      before :each do
        visit '/yields/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
      end

      # test for Redmine issue #2604
      it "should not throw a ActionView::Template::Error when edits are submitted with an invalid field" do
        fill_in 'yield_mean', with: ""
        expect { click_button "Update" }.not_to raise_error do |error|
          expect(error).to be_a(ActionView::Template::Error)
        end
      end

    end

  end


  context 'Logged on as Creator' do
    before :each do
      login_as_creator
    end

    specify 'Creators can delete yields they themselves create', js: true do
      visit '/citations'
      first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/')]").click

      visit '/yields/new'

      # Required attributes:
      fill_in 'yield[mean]', :with => '10.0'
      select('10', :from => 'yield[date(3i)]')
      select('10', :from => 'yield[date(2i)]')
      select('1800', :from => 'yield[date(1i)]')
      fill_in 'species_query', :with => 'Abar'
      select('2', :from => 'yield[specie_id]')

      # Change from default (1) so Manager can see this record:
      select('4', from: 'yield[access_level]')
      click_button 'Create'

      # Now try to go and delete the record just created:
      visit '/yields'

      ## Having multiple expectations in this test will help pinpoint exactly
      ## where the error occurs (if it does occur):
      expect(page).to have_xpath(".//tr/td/a[text() = 'Abarema jupunba']")
      expect(page).to have_xpath(".//tr[td/a/text() = 'Abarema jupunba']/td/a[@alt = 'delete']")

      first(:xpath, ".//tr[td/a/text() = 'Abarema jupunba']/td/a[@alt = 'delete']").click
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end

      expect(page).not_to have_content 'Abarema jupunba'
    end


    specify "Creators can't delete yields they themselves didn't create" do
      visit '/yields'

      ## Having multiple expectations in this test will help pinpoint exactly
      ## where the error occurs (if it does occur):
      ### Make sure there is some record ...:
      expect(page).to have_xpath(".//tr/td/a[contains(text(), 'Aliartos, Greece')]")
      ### ... but it shouldn't have a delete button:
      expect(page).not_to have_xpath(".//tr[td/a[contains(text(), 'Aliartos, Greece')]]/td/a[@alt = 'delete']")
    end

  end

end


