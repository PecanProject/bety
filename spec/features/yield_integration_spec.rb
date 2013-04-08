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
    end

    it 'should allow creation of new yields after selecting a citation' do
      first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/')]").click

      visit '/yields/new'
      fill_in 'Mean', :with => '10.0'
      fill_in 'N', :with =>  '100'

      fill_in 'Notes', :with =>  'In some technical publications, appendices are so long and important as part of the book that they are a creative endeavour of the author'
      click_button 'Create'
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

    context 'clicking use yield button' do
      it 'should return "Sites already associated with this yield" ' do
        visit '/yields/'
        first(:xpath,".//a[@alt='use' and contains(@href,'/use_yield/')]").click
        page.should have_content 'Sites already associated with this yield'
      end
    end

  end
end


