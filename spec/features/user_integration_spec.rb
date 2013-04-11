require 'spec_helper'
include LoginHelper

feature 'Users index works' do
  before :each do
    login_test_user
  end

  context 'GET /users' do
    it 'should have "Listing Users" ' do
      visit '/users'
      page.should have_content 'Listing Users'
    end

   context 'clicking view user button' do
      it 'should return "Viewing User" ' do
        visit '/users/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/users/')]").click
        page.should have_content 'Viewing User'
      end
    end
    
    context 'clicking edit user button' do
      it 'should return "Editing User" ' do
        visit '/users/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing User'
      end
    end
    
    
  end
end


