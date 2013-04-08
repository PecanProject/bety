require 'spec_helper'
include LoginHelper

feature 'Ensembles work' do
  before :each do
    login_test_user
  end

  context 'GET /ensembles' do
    it 'should have "Listing Ensembles" ' do
      visit '/ensembles'
      page.should have_content 'Listing Ensembles'
    end

    it 'should have "New Ensemble" ' do
      visit '/ensembles/new'
      page.should have_content 'New Ensemble'
    end

    it 'should allow creation of new ensembles' do
      visit '/ensembles/new'
      select('ENS', :from => 'Runtype')
      fill_in 'Notes', with: 'emerging biofuel industry may aid in reducing greenhouse gas'

      click_button 'Create'
      
      page.should have_content 'Ensemble was successfully created'
    end

    context 'clicking view ensemble button' do
      it 'should return "Viewing Ensemble" ' do
        visit '/ensembles/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/ensembles/')]").click
        page.should have_content 'Viewing Ensemble'
      end
    end
    
    context 'Edit ensemble page' do
      it 'should have_content "Editing Ensemble" ' do
        visit '/ensembles/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing Ensemble'
      end
      
      it 'should allow a ensemble to be edited' do
        visit '/ensembles/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        fill_in 'Notes', with: 'in reducing greenhouse gas'

        click_button 'Update'
        page.should have_content 'Ensemble was successfully updated.'
      end
    end

  end
end

