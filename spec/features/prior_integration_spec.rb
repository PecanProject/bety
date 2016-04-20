require 'support/helpers'
include LoginHelper, AutocompletionHelper

feature 'Priors index works' do
  before :each do
    login_test_user
  end

  context 'GET /priors' do
    it 'should have "Listing Priors" ' do
      visit '/priors'
      expect(page).to have_content 'Listing Priors'
    end

    it 'should allow creation of new  priors', js:true do
      visit '/priors/new'

      fill_autocomplete "search_variables", with: "Amax", select: "Amax"

      fill_in 'Phylogen', :with => 'Bats'
      fill_in 'prior_parama', :with =>'1.34'
      fill_in 'prior_paramb', :with => '5.622'
      fill_in 'prior_n', :with => '9999'
      fill_in 'Notes', :with => 'for querying the page for the existence of certain elements'

      click_button 'Create'

      expect(page).to have_content 'Prior was successfully created'


      # now do clean-up
      visit '/priors'
      page.find(:xpath, ".//table/tbody/tr[contains(., 'Bats')]/td/a[@alt = 'delete']").click
      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end

    end

    context 'clicking view prior button' do
      it 'should return "Viewing Prior" ' do
        visit '/priors/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/priors/')]").click
        expect(page).to have_content 'Viewing Prior'
      end
    end
    
    context 'clicking edit prior button' do

      before :each do
        visit '/priors/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
      end

      it 'should return "Editing Prior" ' do
        expect(page).to have_content 'Editing Prior'
      end

      it 'should allow adding related pfts', js: true do
        click_link 'View Related PFTs'
        fill_in 'search_pfts', with: 'temperate.Northern_Pine'
        click_link '+'
        expect(page).to have_content 'temperate.Northern_Pine'
        expect(page).to have_content 'X' # this seems to be needed
        click_button 'Update'
        # reopen related pfts listing
        click_link 'View Related PFTs'
        expect(page).to have_content 'temperate.Northern_Pine'

        # now do clean-up:
        fill_in 'search_pfts', with: 'temperate.Northern_Pine'
        click_link 'X'
        expect(page).to have_content '+' # this seems to be needed
        click_button 'Update'
        # reopen related pfts listing
        click_link 'View Related PFTs'
        expect(page).not_to have_content 'temperate.Northern_Pine'
      end

    end


  end
end


