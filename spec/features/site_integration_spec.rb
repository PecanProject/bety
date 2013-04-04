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
      visit '/sites/new'
      fill_in 'Site name', with:'tester'
      fill_in 'Elevation (m)', with: '2900'
      fill_in 'Mean Annual Precipitation (mm/yr)', with:'11/90'
      fill_in 'Mean Annual Temperature (°C)', with: '90009'
      fill_in 'City', with:'Taipei'
      fill_in 'State', with:'hungsha'
      select('UNITED STATES', :from => 'Country')
      fill_in 'Notes', with: 'working with and manipulating those elements'
      fill_in 'Soil Notes', with: 'methods available, so you can restrict them to specific parts of the page'
      click_button 'Create'
      
      page.should have_content 'Site was successfully created'
    end

    context 'clicking view site button' do
      it 'should return "Viewing Site" ' do
        visit '/sites/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/sites/')]").click
        page.should have_content 'Viewing Site'
      end
    end
    
    context 'clicking edit site button' do
      it 'should return "Editing Site" ' do
        visit '/sites/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing Site'
      end
    end

    context 'clicking use site button' do
      it 'should return "Sites already associated with this site" ' do
        visit '/sites/'
        first(:xpath,".//a[@alt='use' and contains(@href,'/use_site/')]").click
        page.should have_content 'Sites already associated with this site'
      end
    end

  end
end


