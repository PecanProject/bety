require 'spec_helper'
include LoginHelper

feature 'Pfts index works' do
  before :each do
    login_test_user
  end

  context 'GET /pfts' do
    it 'should have "Listing pfts" ' do
      visit '/pfts'
      page.should have_content 'Listing PFTs'
    end

    # tests for redmine bug #1936
    it 'should redirect to the home page if user is logged out' do
      visit '/pfts'
      click_link 'Logout'
      visit '/pfts'
      page.should have_content "Welcome to BETYdb"
    end

    it 'should allow creation of new pfts' do
      visit '/pfts/new'
      fill_in 'Name', :with =>'tester'
      fill_in 'Definition', :with => '2900'
      click_button 'Create'
      
      page.should have_content 'Pft was successfully created'
    end

    context 'clicking view citation button' do
      it 'should return "Viewing Pft" ' do
        visit '/pfts/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/pfts/')]").click
        page.should have_content 'Viewing PFT'
      end
    end
    
    context 'clicking edit citation button' do
      it 'should return "Editing Pft" ' do
        visit '/pfts/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing PFT'
      end
    end

    # test for redmine bug #1935
    context 'searching for species' do
      it 'should find a searched-for existing species' do

        # Couldn't get AJAX-triggered search to work here, so have to
        # do it this way; the 'right' way to test this is to visit the
        # edit pft page, view the related species, and type a search
        # into the search box.

        some_pft_id = Pft.first.id
        visit "/pfts/edit2_pfts_species/#{some_pft_id}?search=Abarema+jupunba"
        # The returned 'page' is actually the text of the Prototype "Element.update" calls.
        page.should have_content 'Abarema jupunba'
      end

      it 'should not be case-sensitive' do

        # see not above
        some_pft_id = Pft.first.id
        visit "/pfts/edit2_pfts_species/#{some_pft_id}?search=ABAREMA+JUPUNBA"
        # The returned 'page' is actually the text of the Prototype "Element.update" calls.
        page.should have_content 'Abarema jupunba'
      end

    end
  end
end




