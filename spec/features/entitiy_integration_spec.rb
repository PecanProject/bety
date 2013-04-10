require 'spec_helper'
include LoginHelper

feature 'Entities index works' do
  before :each do
    login_test_user
  end

  context 'GET /entities' do
    it 'should have "Listing Entities" ' do
      visit '/entities'
      page.should have_content 'Listing Entities'
    end

    it 'should have "New Entity" ' do
      visit '/entities/new'
      page.should have_content 'New Entity'
    end

    it 'should allow creation of new entities' do
      visit '/entities/new'
      fill_in 'Name', :with => 'dingos'
      fill_in 'Notes', :with => 'emerging biofuel industry may aid in reducing greenhouse gas'

      click_button 'Create'
      
      page.should have_content 'Entity was successfully created'
    end

    context 'clicking view entity button' do
      it 'should return "Viewing Entity" ' do
        visit '/entities/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/entities/')]").click
        page.should have_content 'Viewing Entity'
      end
    end
    
    context 'Edit entity page' do
      it 'should have_content "Editing Entity" ' do
        visit '/entities/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing Entity'
      end
    end      

    context 'Editing existing entity' do
      it 'should allow a entity to be edited' do
        visit '/entities/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click

        fill_in 'Notes', :with => 'in reducing greenhouse gas'

        click_button 'Update'
        page.should have_content 'Entity was successfully updated.'
      end
    end

  end
end
