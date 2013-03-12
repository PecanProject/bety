require 'spec_helper'
include LoginHelper

feature 'Methods index works' do
  before :each do
    login_test_user
  end

  context 'GET /methods' do
    it 'should have "Listing methods" ' do
      visit '/methods'
      page.should have_content 'Listing methods'
    end

  end
end


