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
