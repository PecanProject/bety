require 'spec_helper'
include LoginHelper

feature 'Managements index works' do
  before :each do
    login_test_user
  end

  context 'GET /managements' do
    it 'should have "Listing Managements" ' do
      visit '/managements'
      page.should have_content 'Listing Managements'
    end

    it 'should allow creation of new managments' do
      ## pending
    end

    context 'clicking view managment button' do
      it 'should return "Viewing Management" ' do
        visit '/managements/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/managements/')]").click
        page.should have_content 'Viewing Management'
      end
    end
    
    context 'clicking edit managment button' do
      it 'should return "Editing Management" ' do
        visit '/managements/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing Management'
      end
    end

  end
end


