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

    describe "  users with access equal to 1" do
    it ' should see more than 1 users in list' do
      
      #current_user = User.new;
     expect all(:xpath,".//tr/td").length >= 2
    
    #test for visitor
    end
  end

    
    
  end
end

feature ' User index for nonadministrators' do
 
  before :each do
    login_nonadmin_test_user
  end

  describe " click on the data link" do
  
    it 'should contains the link of user page' do
      visit root_path
      click_link "Users"
      page.should have_content 'Listing Users'

    end
  end


  


  describe " users with access greater than 1" do
    it ' show see more than 1 users in list ' do
    expect all(:xpath,".//tr/td").length ==1 
    #test for administrator
    end
  end

  


end

