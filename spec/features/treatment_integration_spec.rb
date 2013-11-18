require 'spec_helper'
include LoginHelper

feature 'Treatment index works' do
  before :each do
    login_test_user
  end

  context 'GET /treatments/new' do
    it 'should have "New Treatment" ' do
      visit '/treatments/new'
      
      page.should have_content 'New Treatment'
    end

    it 'should allow creation of new treatments' do
      visit '/treatments/new'
      fill_in 'Name', :with => 'tester'
      fill_in 'Definition', :with => 'Light utilization anddddd'
      select('True', :from => 'Control')

      click_button 'Create'
      
      page.should have_content 'Treatment was successfully created'
    end
  end

  
  
  context 'GET /treatments/' do
    it 'should return "Listing Treatments" ' do
      visit '/treatments/'

      page.should have_content 'Listing Treatments'
    end

    it 'should return "Listing Treatments" even if a citation has been chosen' do
      visit(citations_path)
      first(:xpath, ".//td[preceding-sibling::td[text() = 'Adler']]/a[contains(@href, 'use_citation')]").click
      visit(treatments_path)
      page.should have_content 'Listing Treatments'
    end
    
    it 'following edit link should return content "Editing Treatment" ' do
      visit '/treatments/'
      first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
      page.should have_content 'Editing Treatment'
    end
  end


end


