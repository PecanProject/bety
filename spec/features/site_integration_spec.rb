require 'support/helpers'
include LoginHelper

feature 'Sites index works' do
  before :each do
    login_test_user
  end

  context 'GET /sites' do
    it 'should have "Listing Sites" ' do
      visit '/sites'
      expect(page).to have_content 'Listing Sites'
    end

    it 'should allow creation of new sites' do
      visit '/citations'
      first(:xpath,".//a[contains(@href,'/use_citation/')]").click
      
      visit '/sites/new'
      
      fill_in 'Site name', :with =>'tester'
      fill_in 'Lat', with: '25.03'
      fill_in 'Lon', with: '121.63'
      fill_in 'Elevation (m)', :with => '346'
      fill_in 'Mean Annual Precipitation (mm/yr)', :with => '672'
      fill_in 'Mean Annual Temperature', :with => '19'
      fill_in 'City', :with => 'Taipei'
      select('CHINA', :from => 'Country')
      fill_in 'site_notes', :with => 'working with and manipulating those elements'
      fill_in 'site_soilnotes', :with => 'methods available, so you can restrict them to specific parts of the page'

      click_button 'Create'
      
      expect(page).to have_content 'Site was successfully created'
    end

    context 'clicking view site button' do
      it 'should return "Viewing Site" ' do
        visit '/sites/'
         first(:xpath,".//a[contains(@alt,'show')]").click
        expect(page).to have_content 'Viewing Site'
      end
    end
    
    context 'clicking edit site button' do
      
      before :each do
        visit '/sites/'
        first(:xpath,".//a[ contains(@alt,'edit')]").click
      end

      it 'should return "Editing Site" ' do
        expect(page).to have_content 'Editing Site'
      end

      it 'show allow adding new related citations', js: true do
        click_link 'View Related Citations'
        fill_in 'search_citations', with: 'Wood'
        # In Ruby 2.6 especially, merely filling in a field doesn't seem to
        # trigger the needed keyup event, so do it manually:
        find_field('search_citations').trigger(:keyup)
        click_link '+'
        click_button 'Update'
        # reopen related citations listing
        click_link 'View Related Citations'
        expect(page).to have_content 'Wood'

        # now do clean-up:
        fill_in 'search_citations', with: 'Wood'
        click_link 'X'
        click_button 'Update'
        # reopen related citations listing
        click_link 'View Related Citations'
        expect(page).not_to have_content 'Wood'
      end      

      # Test for github bety issue #439
      specify 'clicking update without changing anything should not produce an error', js: true do
        click_button 'Update'
        expect(page).not_to have_content 'error'
      end

    end

    context 'clicking use site button' do
      ## pending
    end

  end
end


