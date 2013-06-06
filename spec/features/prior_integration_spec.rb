require 'spec_helper'
include LoginHelper

feature 'Priors index works' do
  before :each do
    login_test_user
  end

  context 'GET /priors' do
    it 'should have "Listing Priors" ' do
      visit '/priors'
      page.should have_content 'Listing Priors'
    end

    it 'should allow creation of new  priors' do
      visit '/priors/new'
      
      fill_in 'Phylogen', :with => 'Bats'
      fill_in 'prior_parama', :with =>'ZOMG A'
      fill_in 'prior_paramb', :with => 'Beez Interwebs Papers'
      fill_in 'prior_n', :with => '9999'
      fill_in 'Notes', :with => 'for querying the page for the existence of certain elements'

      click_button 'Create'
      
      page.should have_content 'Prior was successfully created'
    end

    context 'clicking view prior button' do
      it 'should return "Viewing Prior" ' do
        visit '/priors/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/priors/')]").click
        page.should have_content 'Viewing Prior'
      end
    end
    
    context 'clicking edit prior button' do
      it 'should return "Editing Prior" ' do
        visit '/priors/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing Prior'
      end
    end


  end
end


