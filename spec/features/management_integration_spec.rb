require 'spec_helper'
include LoginHelper

feature 'Managements index works' do
  before :each do
    login_test_user
  end

  context 'GET /managements' do
    it 'should have "Listing managements" ' do
      visit '/managements'
      page.should have_content 'Listing managements'
    end

  end
end


