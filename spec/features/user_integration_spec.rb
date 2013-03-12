require 'spec_helper'
include LoginHelper

feature 'Users index works' do
  before :each do
    login_test_user
  end

  context 'GET /users' do
    it 'should have "Listing users" ' do
      visit '/users'
      page.should have_content 'Listing Users'
    end

  end
end


