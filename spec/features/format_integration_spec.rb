require 'spec_helper'
include LoginHelper

feature 'Formats index works' do
  before :each do
    login_test_user
  end

  context 'GET /formats/new' do
    it 'should have "New Format" ' do
      visit '/formats/new'
      page.should have_content 'New Format'
    end

    it 'should allow creation of new formats' do
      visit '/formats/new'
      fill_in 'mime_type_other', :with =>'DATA'
      fill_in 'Name', :with =>'PAPER'
      fill_in 'Header', :with => 'Research'
      fill_in 'Skip', :with =>'DEAR'
      fill_in 'Dataformat', :with =>'XML'
      fill_in 'Notes', :with => 'DingoesDingoesDingoesDingoesDingoes'
      click_button 'Create'
      
      page.should have_content 'Format was successfully created'
    end

    context 'clicking view format button' do
      it 'should return "Viewing Format" ' do
        visit '/formats/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/formats/')]").click
        page.should have_content 'Viewing Format'
      end
    end
    
    context 'clicking edit format button' do
      it 'should return "Editing format" ' do
        visit '/formats/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing Format'
      end
    end

  end
end


