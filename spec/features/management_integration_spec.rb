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

feature 'Creating a new management for a treatment associated with a citation works' do
  before :each do
    login_test_user
  end

  context "when a citation has been selected" do
    before :each do
      visit(citations_path)
      first(:xpath, ".//a[@alt = 'use']").click
    end
    it 'should display the new management form' do
      visit(treatments_path)
      first(:xpath, ".//a[text() = 'New Management for this treatment']").click
      page.should_not have_content "We're sorry"
    end
    it 'should not have a citations select box' do
      visit(treatments_path)
      first(:xpath, ".//a[text() = 'New Management for this treatment']").click
      page.should_not have_selector(:xpath, '//select[@name="management[citation_id]"]')
    end      
  end
end


feature 'Attempting to create a new management' do
  before :each do
    login_test_user
  end

  context "when no citation has been selected" do
    it 'should display the message "Please choose a citation to work with first."' do
      visit(managements_path)
      first(:xpath, ".//a[text() = 'New Management']").click
      page.should have_content "Please choose a citation to work with first."
    end
  end

  context "when the selected citation has no associated treatment" do
    it 'should display the message "You must associate a treatment with this citation before adding a new management"' do
      visit(citations_path)
      first(:xpath, ".//tr[contains(td, 'Adler')]/td/a[@alt = 'use']").click
      visit(managements_path)
      first(:xpath, ".//a[text() = 'New Management']").click
      page.should have_content "You must associate a treatment with this citation before adding a new management"
    end
  end
end

feature 'Searching managements' do
  before :each do
    login_test_user
  end

  context "When searching for a management inside the management listings" do
    it 'should display the search results page' do
      begin
        visit '/managements?utf8=%E2%9C%93&DataTables_Table_0_length=25&search=use&direction=&sort='
      rescue
        fail 'searching caused error'
      end
    end
  end
end
