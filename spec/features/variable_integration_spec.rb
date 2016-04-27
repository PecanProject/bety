require 'support/helpers'
include LoginHelper

feature 'Variables index works' do
  before :each do
    login_test_user
  end

  context 'GET /variables' do
    it 'should have "Listing variables" ' do
      visit '/variables'
      expect(page).to have_content 'Listing Variables'
    end

    it 'should allow creation of new variables' do
      visit '/variables/new'
      fill_in 'Name', :with => 'A (P)'
      fill_in 'Description', :with => 'Biomass of living parts of plant (stem+Leaves)'
      fill_in 'Units', :with => 'g plant-1'
      fill_in 'Notes', :with => 'If measured for part of year (e.g. growing season ET), add start date and end date as covariates.'

      click_button 'Create'
      
      expect(page).to have_content 'Variable was successfully created'
    end

    context 'clicking view variable button' do
      it 'should return "Viewing Variable" ' do
        visit '/variables/'
        
        first(:xpath,".//a[@alt='show' and contains(@href,'/variables/')]").click
        expect(page).to have_content 'Viewing Variable'
      end
    end
    
    context 'clicking edit variable button' do
      it 'should return "Editing Variable" ' do
        visit '/variables/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        expect(page).to have_content 'Editing Variable'
      end
    end

  end
end


