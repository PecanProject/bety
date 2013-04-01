require 'spec_helper'
include LoginHelper

feature 'Cultivars index works' do
  before :each do
    login_test_user
  end

  context 'GET /cultivars' do
    it 'should have "Listing Cultivars" ' do
      visit '/cultivars'
      page.should have_content 'Listing Cultivars'
    end
  end

  context 'GET /cultivars/new' do
    it 'should return "Cultivar was successfully created" ' do
      visit '/cultivars/new'
      
      fill_in 'Previous', :with => 'tester'
      fill_in 'Name', with: 'Dingosville'
      fill_in 'Ecotype', with: 'Boreal'
      fill_in 'Notes', with: 'Neque porro quisquam est qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit...'
      click_button 'Create'
      
      page.should have_content 'Cultivar was successfully created'
    end
  end
  
  context 'clicking view cultivar button' do
    it 'should return "Viewing Cultivar" ' do
      visit '/cultivars/'
      first(:xpath,".//a[@alt='show' and contains(@href,'/cultivars/')]").click
      page.should have_content 'Viewing Cultivar'
    end
  end
  
  context 'Edit cultivar page' do
    it 'should return "Editing Cultivar" ' do
      visit '/cultivars/'
      first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
      page.should have_content 'Editing Cultivar'
    end
  end
  
  context 'Editing a cultivar' do
    it 'should allow a cultivar to be edited' do
      visit '/cultivars/'
      first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click

      fill_in 'Previous', with: 'Plantesque'
      
      print page.body

      click_button 'Update'
      page.should have_content 'Cultivar was successfully updated.'
    end
    
  end  
  
  
end
