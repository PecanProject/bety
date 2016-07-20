require 'support/helpers'
include LoginHelper

feature 'Models features work' do
  before :each do
    login_test_user
  end

  specify 'The model edit page should be accessible' do
    visit '/models/'
    first(:xpath, './/a[@alt = "edit"]').click
    expect(page).to have_content 'Editing Model'
  end

  context 'Editing Model collections' do

    it 'should allow unlinking and re-linking a file', js: true do

      # first make an un-attached dbfile to work with:
      visit '/dbfiles'
      click_link 'New file'
      fill_in 'File path', with: '/'
      fill_in 'File name', with: 'TEST'
      click_button 'Create'

      visit  '/models/'
      first(:xpath, './/a[@alt = "edit"]').click
      click_link 'View Related Files'

      # re-add file
      fill_in 'filesearch', with: 'TEST'
      sleep 1 # need time for search results to appear
      first(:xpath, ".//a[text() = '+']").click

      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end

      click_link 'Show only related results'

      expect(page).to have_link('X')

      # unlink file
      first(:xpath, ".//a[text() = 'X']").click

      # If we're using Selenium, we have to deal with the modal dialogue:
      if page.driver.is_a? Capybara::Selenium::Driver
        a = page.driver.browser.switch_to.alert
        a.accept
      end

      expect(page).not_to have_link('X')
    end

  end

end
