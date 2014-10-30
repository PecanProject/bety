require 'spec_helper'

module LoginHelper
  def login_test_user
    visit root_path
    fill_in 'Login',    :with => 'test_admin_user'
    fill_in 'Password', :with => 'Ciuleandra'
    click_button 'Log in'
  end

  def login_nonadmin_test_user
    visit root_path
    fill_in 'Login',    :with => 'robben_yang'
    fill_in 'Password', :with => 'paozong'
    click_button 'Log in'
  end
end

module BulkUploadHelper
  def choose_citation_from_dropdown(author = 'Adler')
    ### If we were *only* going to use the Selenium driver, we could do
    ### this.  But capybara-webkit doesn't have a send_keys method.
    # control = page.driver.browser.find_element(:id, 'autocomplete_citation')
    # control.send_keys 'Adler'
    # sleep 1
    # control.send_keys :arrow_down
    # control.send_keys :return

    ### This should work with either Selenium or Capybara-Webkit:
    page.execute_script("jQuery('#autocomplete_citation').val('#{author}')")
    sleep 1 # maybe not needed
    page.execute_script("jQuery('#autocomplete_citation').trigger('keydown', {keyCode: 40})")
    sleep 1 # necessary!
    first("#ui-id-1 li.ui-menu-item a").click
    click_button "View Validation Results"
  end
end

