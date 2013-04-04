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

    it 'should allow creation of new pfts' do
      visit '/pfts/new'
      fill_in 'Name', with:'tester'
      fill_in 'Definition', with: '2900'
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

  end
end




