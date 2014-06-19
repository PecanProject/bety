# test for redmine task #1908
require 'spec_helper'
include LoginHelper

feature 'Posteriors search' do
  before :each do
    login_test_user
  end
 

  it 'should list posteriors' do
    visit '/posteriors'
    expect(page).to have_content 'Listing Posteriors'
  end


  context 'search on posteriors' do
    it 'should show search result on current page', :js => true do
      visit '/posteriors'
      fill_in 'search', :with => 'testsearch'        
      expect(page).to have_content 'No entries'
    end
    it 'should show search result on new page' do
      visit '/posteriors?search=testsearch'
      expect(page).to have_content 'No entries'
    end
  end
end

feature'Posterior edit' do
  it 'should show edit page' do
    login_test_user
    visit '/posteriors/1/edit'
    page.should have_content "Editing Posterior"
  end
end
