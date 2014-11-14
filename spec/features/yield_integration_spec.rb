require 'spec_helper'
include LoginHelper

feature 'Yields index works' do
  before :each do
    login_test_user
  end

  context 'GET /yields' do
#    it 'should have "Listing Yields" ' do
#      visit '/yields'
#      page.should have_content 'Listing Yields'
#    end

    it 'should forward to citations index when clicking "New Yield" ' do
      visit '/yields'
      click_link 'New Yield'
      
      page.should have_content 'Choose a citation to work with ( Actions Tab > Check )'
      page.should have_content 'Listing Citations'
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
      
      page.should have_content 'Yield was successfully created.'

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
      
      page.should have_content 'Mean is not a number'
    end

    context 'clicking view yield button' do
      it 'should return "Viewing Yield" ' do
        visit '/yields/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/yields/')]").click
        page.should have_content 'Viewing Yield'
      end
    end
    
    context 'clicking edit yield button' do
      it 'should return "Editing Yield" ' do
        visit '/yields/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing Yield'
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
        expect { click_button "Update" }.not_to raise_error(ActionView::Template::Error)
      end

    end

  end
end


