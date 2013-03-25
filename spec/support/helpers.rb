require 'spec_helper'

module LoginHelper
  def login_test_user
    visit login_path
    fill_in 'Login',    :with => 'carlcrott'
    fill_in 'Password', :with => 'asdfasdf'
    click_button 'Log in'
  end
end

