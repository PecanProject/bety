require 'support/helpers'
include LoginHelper

feature 'Pfts features work works' do
  before :each do
    login_test_user
  end

  context 'GET /pfts' do

    before :each do
      visit '/pfts'
    end

    it 'should have "Listing pfts" ' do
      expect(page).to have_content 'Listing PFTs'
    end

    # tests for redmine bug #1936
    it 'should redirect to the home page if user is logged out' do
      click_link 'Logout'
      visit '/pfts'
      expect(page).to have_content "Welcome to BETYdb"
    end

  end

  context 'Creating Pfts' do

    it 'should allow creation of new pfts' do
      visit '/pfts/new'
      fill_in 'Name', :with =>'tester'
      fill_in 'Definition', :with => '2900'
      click_button 'Create'
      
      expect(page).to have_content 'Pft was successfully created'
    end

  end


  context 'clicking view pft button' do
    it 'should return "Viewing Pft" ' do
      visit '/pfts/'
      first(:xpath,".//a[@alt='show' and contains(@href,'/pfts/')]").click
      expect(page).to have_content 'Viewing PFT'
    end
  end
  
  context 'clicking edit pft button' do

    before :each do
      visit '/pfts/'
      first(:xpath, ".//a[@alt='edit' and contains(@href,'/edit')]").click
    end

    it 'should return "Editing Pft" ' do
      expect(page).to have_content 'Editing PFT'
    end

    it 'should allow adding a related prior', js: true do
      click_link 'View Related Priors'
      fill_in 'search_priors', with: 'plants'

      # Since there is another '+' link on the page, we resort to this:
      first(:css, "table#priors").find(:xpath, ".//a[text() = '+']").click

      click_button 'Update'
      # go back to edit page and reopen related priors listing
      click_button "Edit Record"
      click_link 'View Related Priors'
      expect(page).to have_text 'plants'

      # now do clean-up:
      click_link 'X'
      click_button 'Update'
    end

    it 'should allow searching for species', js: true do
      click_link "View Related Species"
      fill_in 'search', with: 'Lolium'
      expect(page).to have_link 'Lolium perenne'
    end


    it 'should allow adding a new species', js: true do
      click_link "View Related Species"
      fill_in 'search', with: 'Lolium'
      expect(page).to have_xpath ".//tr[contains(string(.), 'Lolium')]/td/a[text() = '+']"
      first(:xpath, ".//tr[contains(string(.), 'Lolium')]/td/a[text() = '+']").click
      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end
      expect(page).to have_xpath(".//tr[td/a[contains(text(), 'Lolium perenne')]]/td/a[text() = 'X']")


      # now do clean-up:
      page.find(:xpath, ".//tr[td/a[contains(text(), 'Lolium perenne')]]/td/a[text() = 'X']").click
      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end

    end


  end

  # test for redmine bug #1935
  context 'searching for species' do

    # TO-DO: Implement these tests the 'right' way, and then eliminate the route they depend upon.

    it 'should find a searched-for existing species' do

      # Couldn't get AJAX-triggered search to work here, so have to
      # do it this way; the 'right' way to test this is to visit the
      # edit pft page, view the related species, and type a search
      # into the search box.

      some_pft_id = Pft.first.id
      visit "/pfts/edit2_pfts_species/#{some_pft_id}?search=Abarema+jupunba"
      # The returned 'page' is actually the text of the Prototype "Element.update" calls.
      expect(page).to have_content 'Abarema jupunba'
    end

    it 'should not be case-sensitive' do

      # see not above
      some_pft_id = Pft.first.id
      visit "/pfts/edit2_pfts_species/#{some_pft_id}?search=ABAREMA+JUPUNBA"
      # The returned 'page' is actually the text of the Prototype "Element.update" calls.
      expect(page).to have_content 'Abarema jupunba'
    end

  end

  # test for redmine bug #1784
  it 'should not create a new PFT when the Back button is clicked' do
    visit '/pfts/new'
    click_button 'All Records'
    expect(page).not_to have_content 'Pft was successfully created.'
  end
  
end





