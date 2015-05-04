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

      before :each do
        visit '/priors/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
      end

      it 'should return "Editing Prior" ' do
        page.should have_content 'Editing Prior'
      end

      it 'should allow adding related pfts', js: true do
        click_link 'View Related PFTs'
        page.select 'temperate.Northern_Pine', from: 'pft_id'
        click_button 'Select'
        page.should have_content 'temperate.Northern_Pine'

        # now do clean-up
        page.find(:xpath, ".//table/tbody/tr[preceding-sibling::tr/th/text() = 'Name'][contains(td[3], 'temperate.Northern_Pine')]/td/a[text() = 'X']").click
        # If we're using Selenium, we have to deal with the modal dialogue:
        if page.driver.is_a? Capybara::Selenium::Driver
          a = page.driver.browser.switch_to.alert
          a.accept
        end

        
      end

    end


  end
end


