require 'support/helpers'
include LoginHelper

feature 'Inputs features work' do
  before :each do
    login_test_user
    visit '/inputs/'
  end

  specify 'The input edit page should be accessible' do
    first(:xpath, './/a[@alt = "edit"]').click
    expect(page).to have_content 'Editing Input'
  end

  context 'Editing Input collections' do

    before :each do
      first(:xpath, './/a[@alt = "edit"]').click
    end

    it 'should allow unlinking and re-linking a file', js: true do
      click_link 'View Related Files'

      # unlink file
      first(:xpath, ".//a[text() = 'X']").click

      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end

      expect(page).not_to have_link('X')

      # re-add file
      fill_in 'filesearch', with: 'CA'
      sleep 1 # need time for search results to appear
      first(:xpath, ".//a[text() = '+']").click

      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end

      expect(page).to have_link('X')
    end

  end

end
