require 'spec_helper'
include LoginHelper

feature 'Traits index works' do
  before :each do
    login_test_user
  end

  context 'GET /traits' do
    it 'should have "Listing Traits" ' do
      visit '/traits'
      page.should have_content 'Listing Traits'
    end

    context 'clicking view trait button' do
      it 'should return "Viewing Trait" ' do
        visit '/traits/'
        
        first(:xpath,".//a[@alt='show' and contains(@href,'/traits/')]").click
        page.should have_content 'Viewing Trait'
      end
    end


    ## pending
    it 'should allow creation of new traits' do
#      # Create Citation association
#      visit '/citations'
#      first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/')]").click
#      page.should have_content 'Sites already associated with this citation'

#      # Create Treatment association
#      visit '/treatments'
#      click_link 'New Treatment'
#      fill_in 'Name', :with => 'Erduah'
#      fill_in 'Definition', :with => 'Hot Earth'
#      click_button 'Create'

#      # Create Site association
#      visit '/sites'
#      click_link 'New Site'
#      fill_in 'Site name', :with => 'Erduah'
#      fill_in 'site_notes', :with => 'Hot Earth'
#      click_button 'Create'

#      # Verify the trait creation
#      visit '/traits/new'
#      
#      page.should have_content 'New Trait'
#      
#      fill_in 'trait_mean', :with => '238.12'
#      fill_in 'trait_stat', :with => '7.76'
#      fill_in 'trait_n', :with => '3'
#      fill_in 'trait_notes', :with => 'Research Interwebs Papers Research Interwebs PapersResearch Interwebs PapersResearch Interwebs Papers' 

#      print page.body

#      click_button 'Create'
#      
#      page.should have_content 'Trait was successfully created'
    end


    
    context 'clicking edit trait button' do
      it 'should return "Editing Trait" ' do
        visit '/traits/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing Trait'
      end
    end


  end
end


